class ExpressionStmt
	attr_reader :expression

	def initialize expression
		@expression = expression
	end

	def accept visitor
		visitor.visitExpressionStmt self
	end

end

class PrintStmt
	attr_reader :expression

	def initialize expression
		@expression = expression
	end

	def accept visitor
		visitor.visitPrintStmt self
	end

end

class VarDecl
	attr_reader :name, :initializer

	def initialize name, initializer
		@name = name
		@initializer = initializer
	end

	def accept visitor
		visitor.visitVarDeclStmt self
	end

end

class Block
	attr_reader :statements

	def initialize statements
		@statements = statements
	end

	def accept visitor
		visitor.visitBlockStmt self
	end

end

class IfStmt
	attr_reader :condition, :thenBranch, :elseBranch

	def initialize condition, thenBranch, elseBranch
		@condition = condition
		@thenBranch = thenBranch
		@elseBranch = elseBranch
	end

	def accept visitor
		visitor.visitIfStmt self
	end

end

class While
	attr_reader :condition, :body

	def initialize condition, body
		@condition = condition
		@body = body
	end

	def accept visitor
		visitor.visitWhileStmt self
	end

end

class FunDecl
	attr_reader :name, :parameters, :body

	def initialize name, parameters, body
		@name = name
		@parameters = parameters
		@body = body
	end

	def accept visitor
		visitor.visitFunDeclStmt self
	end

end

class ReturnStmt
	attr_reader :keyword, :expression

	def initialize keyword, expression
		@keyword = keyword
		@expression = expression
	end

	def accept visitor
		visitor.visitReturnStmt self
	end

end

