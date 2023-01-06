require "strscan"
require "optparse"

class CalcError < StandardError
end

class Calc
    @@KEYWORDS = {
        "+" => :add,
        "-" => :sub,
        "*" => :mul,
        "/" => :div,
        "(" => :parn_l,
        ")" => :parn_r,
    }

    def initialize()
        # op = OptionParser.new
        # op.on("-d", "--debug", desk = "Debug mode.") { |v| @debug = true }
        # op.parse!(ARGV)

        #ARGV[0]
        # main(ARGV[0])
    end

    def run(text)
        return main(text)
    end

    def main(text)
        p text if @debug

        #文字がなかったときに入力を促すわよ！
        if text.nil? then
            print "input exp: "
            text = STDIN.gets
        end

        text = text.gsub(/[^\d\+\-\*\/\(\)]/, "") #数字と演算子以外の文字削除わよ
        p text if @debug

        @sc = StringScanner.new(text)
        ans = eval(parse())
        ans = "%.15g" % ans #表示の整形わよ
        # print "#{ans}\n"
        return ans
    end

    ## 意味解析
    def eval(exp)
        if exp.instance_of?(Array) then
            case exp[0]
            when :add
                return eval(exp[1]) + eval(exp[2])
            when :sub
                return eval(exp[1]) - eval(exp[2])
            when :mul
                return eval(exp[1]) * eval(exp[2])
            when :div
                raise CalcError, "Division by zero error" if exp[2] == 0 #ゼロ除算エラーわよ
                return eval(exp[1]) / eval(exp[2])
            end
        else
            return exp
        end
    end

    def get_token()
        if @sc.scan(/\d+|[\+\-\*\/\(\)]/) then #数字or演算子
            if @sc[0] =~ /[\+\-\*\/\(\)]/ then #符号
                return @@KEYWORDS[@sc[0]]
            else
                return @sc[0]
            end
        end
    end

    def unget_token()
        @sc.unscan() unless @sc.eos?
    end

    ## Exp
    def expression()
        result = term()
        token = get_token()
        while token == :add or token == :sub
            result = [token, result, term()]
            token = get_token()
        end
        #unget_token(token)
        unget_token()
        p result if @debug
        return result
    end

    ## Term
    def term()
        result = factor()
        token = get_token()
        while token == :mul or token == :div
            result = [token, result, factor()]
            token = get_token()
        end
        #unget_token(token)
        unget_token()
        p result if @debug
        return result
    end

    ## Fact
    def factor()
        token = get_token()
        if token =~ /\d+/ then #トークンがリテラルか
            result = token.to_f() #リテラル
        elsif token == :parn_l then
            result = expression()
            get_token() # 閉じカッコを取り除く（使用しない）
        else
            raise CalcError, "Syntax error"
        end
        p result if @debug
        return result
    end

    def parse()
        expression()
    end
end

