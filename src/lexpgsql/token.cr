module Lexpgsql
  class Token
    property type : Symbol
    property value : String | Nil

    def initialize(@type, @value = nil)
    end
  end
end
