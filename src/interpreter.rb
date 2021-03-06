require_relative "./runtimeError"
require_relative "./logger"
require_relative "./environment"
require_relative "./callable"
require_relative "./natives"
require_relative "./returnError"

class Interpreter
	@globals = Environment.new
	@environment = @globals
	@locals = {}

	@use_resolver = true

	addNatives @environment

	def self.interpret statements
		begin
			statements.each do |stmt|
				execute stmt
			end
		rescue LoxRuntimeError => error
			Logger.runtime_error error
		end
	end

	def self.resolve expr, depth
		@locals[expr] = depth
	end

	def self.lookupVariable name, expr
		depth = @locals[expr]
		if depth
			@environment.get_at depth, name
		else
			@globals.get name
		end
	end

	def self.visitReturnStmt stmt
		value = stmt.expression ? evaluate(stmt.expression) : nil
		raise ReturnError.new value
	end

	def self.visitFunDeclStmt stmt
		function = Function.new stmt, @environment
		@environment.define stmt.name.lexeme, function
	end

	def self.visitCallExpr expr
		function = evaluate expr.callee

		raise LoxRuntimeError.new expr.close_paren, "Can't call non-function" if !function.is_a? Callable

		# this is done while in old calls scope?
		arguments = expr.arguments.map &method(:evaluate)

		if function.arity != arguments.length
			raise LoxRuntimeError.new expr.close_paren,
				"#{function.name} expected #{function.arity} arguments but received #{arguments.length}"
		end
		
		return function.call self, arguments, expr.callee.name
	end

	def self.visitWhileStmt stmt
		execute stmt.body while truthy? evaluate stmt.condition
	end

	def self.visitRubyExpr expr
		eval (evaluate expr.code).to_s
	end

	def self.visitLogicalExpr expr
		left = evaluate expr.left

		if operator.type == :OR
			return left if truthy? left
		
		# AND
		else
			return left if !truthy? left
		end

		return evaluate expr.right
	end

	def self.visitIfStmt stmt
		if truthy? evaluate stmt.condition
			execute stmt.thenBranch
		elsif stmt.elseBranch
			execute stmt.elseBranch
		end
	end

	def self.visitTernaryExpr expr
		if truthy? evaluate expr.condition
			return evaluate expr.first
		else
			return evaluate expr.second
		end
	end

	def self.visitBlockStmt stmt
		executeBlock stmt.statements
	end

	def self.visitAssignmentExpr expr
		value = evaluate expr.expression
		if @use_resolver
			depth = @locals[expr]
			if depth
				@environment.assigng_at(depth, expr.name, value)
			else
				@globals.assign(expr.name, value)
			end
		else
			@environment.assign expr.name, value
		end

	end

	def self.visitVariableExpr expr
		if @use_resolver
			lookupVariable(expr.name, expr)
		else
			@environment.get expr.name
		end
	end

	def self.visitVarDeclStmt stmt
		value = nil
		value = evaluate stmt.initializer if stmt.initializer

		@environment.define stmt.name.lexeme, value
	end

	def self.visitExpressionStmt stmt
		evaluate stmt.expression
	end

	def self.visitPrintStmt stmt
		value = evaluate stmt.expression
		if value.class == NilClass
			puts "nil" 
		else
			puts value
		end
	end

	def self.evaluate expr
		expr.accept self
	end

	def self.execute stmt
		stmt.accept self
	end

	def self.truthy? var
		var != nil && var.class != FalseClass
	end

	def self.equal? first, second
		#Simply inherit Ruby's system
		first.equal? second
	end

	def self.visitBinaryExpr expr
		operator = expr.operator
		left = evaluate expr.left
		right = evaluate expr.right

		case operator.type
			when :MINUS, :MINUS_EQUAL
				Checker.number operator, left, right
				left - right
			when :SLASH
				Checker.number operator, left, right

				# Don't divide by zero
				if right == 0
					raise LoxRuntimeError.new operator, "Dividing by zero is not allowed"
				end

				left / right
			when :ASTERISk
				Checker.number operator, left, right
				left * right
			when :PLUS, :PLUS_EQUAL
				Checker.number_or_string operator, left, right
				
				if left.class == String && right.class == Integer
					return left + right.to_s
				end
				
				if left.class == Integer && right.class == String
					raise LoxRuntimeError.new operator, "Cannot add string to integer"
				end

				left + right

			#comparison
			when :GREATER
				Checker.number operator, left, right
				left > right
			when :GREATER_EQUAL
				Checker.number operator, left, right
				left >= right
			when :LESS
				Checker.number operator, left, right
				left < right
			when :LESS_EQUAL
				Checker.number operator, left, right
				left <= right
			when :BANG_EQUAL
				equal? left, right
			when :EQUAL_EQUAL
				equal? left, right
		end

	end

	def self.visitGroupingExpr expr
		evaluate expr.expression
	end

	def self.visitLiteralExpr expr
		expr.value
	end

	def self.visitUnaryExpr expr
		operator = expr.operator
		right = evaluate expr.right

		case operator.type
			when :MINUS
				Checker.number operator, right
				-right
			when :BANG
				!truthy? right
		end

	end

	def self.executeBlock statements,  environment=nil
		previous_environment = @environment
		if !environment
			@environment = Environment.new @environment
		else
			@environment = environment
		end

		begin
			statements.each do |stmt|
				stmt.accept self
			end
		ensure
			# discard current env and use previous
			@environment = previous_environment
		end
	end

	# getter function
	def self.globals
		@globals
	end

end

class Checker

	def self.number operator, *operands
		raise LoxRuntimeError.new operator, "Operand must be a number" if !operands.all? {|op| op.class == Integer}
	end

	def self.number_or_string operator, *operands
		raise LoxRuntimeError.new operator, "Operand must be a number or string" if !operands.all? {|op| op.class == Integer || op.class == String}
	end

end
