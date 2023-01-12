require "strscan"
require "optparse"
require 'pp'

class NovelLangSyntaxError < StandardError
end

class NovelLang
    @@KEYS = {
        "+" => :add,
        "-" => :sub,
        "*" => :mul,
        "/" => :div,
        "(" => :parn_L,
        ")" => :parn_R,
        "🤔" => :if,
        "🕑" => :loop,
        "⛄" => :calc,
        "📝" => :std_in,
        "「" => :std_out_L,
        "」" => :std_out_R,
        "【" => :var_L,
        "】" => :var_R,
        "（" => :assignment_L,
        "）" => :assignment_R,
        "……" => :section,
        ">" => :greater_than,
        "<" => :less_than,
    }
    @@KEYS_RE = "#{@@KEYS.map { |t| Regexp.escape(t[0]) }.join("|")}"
    #@@KEYS_RE = "[🤔🕑⛄📝「」【】（）><]|……"
    @@RETURN_RE = '\n|\r\n'
    @@STR_RE = '[\w\p{Hiragana}\p{Katakana}\p{Han}]+'
    @@CALC_RE = '[\+\-\*\/\(\)]'
    @@EOP_RE = '\A\s*\z'

    @@TOKEN_RE = "#{@@RETURN_RE}|#{@@KEYS_RE}|#{@@STR_RE}"

    def initialize
        # init
        STDOUT.sync = true
        STDIN.sync = true
        @nl_var_hash = Hash.new(nil)

        # option-parse
        op = OptionParser.new
        op.on("-d", "--debug", desk = "Debug mode.") { |v| @debug = true }
        op.parse!(ARGV)

        # running
        code = read_file(ARGV[0])
        run(code)
        p @nl_var_hash if @debug
    end

    private def run(text)
        p text if @debug

        # text = text.gsub(/[^\d\+\-\*\/\(\)]/, "") #数字と演算子以外の文字削除わよ
        text = text.gsub(/[\r\n]/, "")
        p text if @debug

        @sc = StringScanner.new(text)
        code_array = parse()

        print "\n" if @debug
        pp code_array if @debug
        print "\n" if @debug

        eval(code_array)
        
        #ans = "%.15g" % ans #表示の整形わよ
        # print "#{ans}\n"
        return
    end

    private def sentences()
        result = [:block]
        while s = sentence()
            result.push(s)
        end
        return result
    end

    private def sentence()
        if ret = eop()
            p "Sentence eop: [#{ret}]" if @debug
            return nil
        elsif ret = assignment()
            p "Sentence Assignment: [#{ret}]" if @debug
            return ret
        elsif ret = std_out()
            p "Sentence STD_OUT: [#{ret}]" if @debug
            return ret
        else
            raise NovelLangSyntaxError, "Sentence Error: [#{ret}] 該当するSentenceがありません"
        end
    end

    private def std_out()
        result = [:std_out]
        unless get_token() == :std_out_L
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end

        # ret = get_token() #Stringか数値が帰ってくるはず        
        # unless ret.instance_of?(String) || ret.is_a?(Numeric)
        #     raise NovelLangSyntaxError, "STD_OUT Error: VarError[#{ret}]"
        # end
        unless ret = expression()
            raise NovelLangSyntaxError, "AssignmentError: not found [Expression]"
        end
        result.push(ret)

        unless get_token() == :std_out_R
            raise NovelLangSyntaxError, "STD_OUT Error: not found '」' "
        end

        return result
    end

    private def eop()
        unless get_token() == nil
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end
        return :eop
    end

    private def assignment()
        result = [:assignment]
        unless get_token() == :var_L
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end

        ret = get_token() #Stringが帰ってくるはず
        unless ret.instance_of?(String)
            raise NovelLangSyntaxError, "AssignmentError: VarError[#{ret}]"
        end
        result.push([:var, ret])

        unless get_token() == :var_R
            raise NovelLangSyntaxError, "AssignmentError: not found '】' "
        end

        unless get_token() == :assignment_L
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '（' "
        end

        unless ret = expression()
            raise NovelLangSyntaxError, "AssignmentError: not found [Expression]"
        end
        result.push(ret)

        unless get_token() == :assignment_R
            raise NovelLangSyntaxError, "AssignmentError: not found '）' "
        end
        return result
    end


    private def eval(exp)
        #p exp
            if exp.instance_of?(Array)
            case exp[0]
            when :block
                exp.shift
                while b = exp.shift do
                    p "!!block!! #{b}" if @debug
                    eval(b)
                end
            when :add
                return eval(exp[1]) + eval(exp[2])
            when :sub
                return eval(exp[1]) - eval(exp[2])
            when :mul
                return eval(exp[1]) * eval(exp[2])
            when :div
                raise NovelLangSyntaxError, "Division by zero error" if exp[2] == 0 #ゼロ除算エラーわよ
                return eval(exp[1]) / eval(exp[2])
            when :assignment
                #p "a  #{exp}"
                return @nl_var_hash[eval(exp[1][1])] = eval(exp[2])
            when :var
                #p "var-eval #{exp} #{@nl_var_hash[exp[1]]}"
                return @nl_var_hash[exp[1]]
            when :std_out
                print "#{eval(exp[1])}\n"
            end
        else
            return exp
        end
    end

    private def parse()
        return sentences()
    end

    ## Exp
    private def expression()
        result = term()
        token = get_token()
        while token == :add or token == :sub # or token == :assignment_L or token == :std_out_L
            result = [token, result, term()]
            token = get_token()
        end
        #unget_token(token)
        unget_token() # unless token == :assignment_R or token == :std_out_R

        p "exp : #{result}" if @debug
        return result
    end

    ## Term
    private def term()
        result = factor()
        token = get_token()
        while token == :mul or token == :div
            result = [token, result, factor()]
            token = get_token()
        end
        #unget_token(token)
        unget_token()
        p "term: #{result}" if @debug
        return result
    end

    ## Fact
    private def factor()
        token = get_token()
        if token =~ /\d+/ #トークンがリテラルか
            result = token.to_f() #リテラル
        elsif token == :parn_L
            result = expression()
            if get_token() != :parn_R # 閉じカッコを取り除く
                raise NovelLangSyntaxError, "SyntaxError ')'がありません"
            end
        elsif token == :var_L #変数関係
            var = get_token()
            if var =~ /#{@@KEYS_RE}|#{@@RETURN_RE}|#{@@CALC_RE}/
                raise NovelLangSyntaxError, "SyntaxError 変数名が正しく規定されていません"
            end

            result = [:var, var]           

            if get_token() != :var_R # 閉じカッコを取り除く
                raise NovelLangSyntaxError, "SyntaxError '】'がありません"
            end
        else
            raise NovelLangSyntaxError, "Syntax error factor: '#{token}'"
        end
        p "fact: #{result}" if @debug
        return result
    end

    #-- util --
    # token操作
    private def get_token()
        if @sc.scan(/#{@@TOKEN_RE}/) #token?
            @before_scan = @sc[0] #eos時のunscan用

            if @sc[0] =~ /#{@@KEYS_RE}/ #キーを返す
                p @@KEYS[@sc[0]] if @debug
                return @@KEYS[@sc[0]]
            elsif @sc[0] =~ /#{@@RETURN_RE}/ #改行
                print "return\n\n" if @debug
            elsif @sc[0] =~ /#{@@STR_RE}/ #英字・日本語
                p @sc[0] if @debug
                return @sc[0]
            elsif @sc[0] =~ /#{@@EOP_RE}/ #コードの終端
                p "eop" if @debug
                return nil
            else
                p :bad_token if @debug
                return :bad_token
            end
        end
    end

    private def unget_token()
        unless @sc.eos?
            @sc.unscan()
        else
            raise NovelLangSyntaxError, "SyntaxError: fail token unget" if @before_scan.nil?
            @sc.string = @before_scan
            @before_scan = nil
            #p @sc
        end
        p "unget_token" if @debug
    end

    # read file2txt
    private def read_file(file_path)
        if file_path.nil?
            print("You need to specify the file to open.\n")
            exit 1
        end
        begin
            f = open(file_path, "r")
            res = f.read
            f.close
        rescue Errno::ENOENT
            print("File not found.\n")
            exit 1
        rescue
            print("File open error.\n")
            exit 1
        end
        return res
    end

    # exit
    private def escape(code = 0)
        exit(code)
    end
end

NovelLang.new()
