require "strscan"
require "optparse"

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
    @@KEYS_RE = "#{@@KEYS.map{|t|Regexp.escape(t[0])}.join('|')}"
    #@@KEYS_RE = "[🤔🕑⛄📝「」【】（）><]|……"
    @@RETURN_RE = '\n|\r\n'
    @@STR_RE = '[\w\p{Hiragana}\p{Katakana}\p{Han}]+'
    @@CALC_RE = '[\+\-\*\/\(\)]'

    @@TOKEN_RE = "#{@@RETURN_RE}|#{@@KEYS_RE}|#{@@CALC_RE}|#{@@STR_RE}"

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

        #文字がなかったときに入力を促すわよ！
        if text.nil?
            print "input exp: "
            text = STDIN.gets
        end

        # text = text.gsub(/[^\d\+\-\*\/\(\)]/, "") #数字と演算子以外の文字削除わよ
        text = text.gsub(/[\r\n]/, "")
        p text if @debug

        @sc = StringScanner.new(text)

        while true
            break if @sc.eos?
            eval(parse())
        end
        #ans = "%.15g" % ans #表示の整形わよ
        # print "#{ans}\n"
        return
    end

    ## 意味解析
    # private def sentences()
    #     unless s = sentence()
    #         raise Exception, "あるべき文が見つからない"
    #     end
    #     result = [:block, s]
    #     while s = sentence()
    #         result << s
    #     end
    #     return result
    # end

    private def eval(exp)
        if exp.instance_of?(Array)
            case exp[0]
            when :add
                return eval(exp[1]) + eval(exp[2])
            when :sub
                return eval(exp[1]) - eval(exp[2])
            when :mul
                return eval(exp[1]) * eval(exp[2])
            when :div
                raise NovelLangSyntaxError, "Division by zero error" if exp[2] == 0 #ゼロ除算エラーわよ
                return eval(exp[1]) / eval(exp[2])
            when :assignment_L
                return @nl_var_hash[exp[1]] = eval(exp[2])
            when :var
                return @nl_var_hash[exp[2]]
            when :std_out_L
                print "#{eval(exp[1])}\n"
            end
        else
            return exp
        end
    end

    private def parse()
        expression()
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
        # elsif token == :var_L #変数関係
        #     var = get_token()
        #     if var =~ /#{@@KEYS_RE}/
        #         raise NovelLangSyntaxError, "SyntaxError 変数名が正しく規定されていません"
        #     end

        #     result = [:var, var]

        #     if get_token() != :var_R # 閉じカッコを取り除く
        #         raise NovelLangSyntaxError, "SyntaxError '】'がありません"
        #     end
        # elsif token == :std_out_L
        #     result = [:std_out_L, expression()]
        #     if get_token() != :std_out_R # 閉じカッコを取り除く
        #         raise NovelLangSyntaxError, "SyntaxError '」'がありません"
        #     end       
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
            if @sc[0] =~ /#{@@KEYS_RE}|#{@@CALC_RE}/
                p @@KEYS[@sc[0]]
                return @@KEYS[@sc[0]]
            elsif @sc[0] =~ /#{@@RETURN_RE}/
                print "return\n\n" if @debug
            else
                p @sc[0]
                return @sc[0]
            end
        end
    end

    private def unget_token()
        unless @sc.eos?
            @sc.unscan()
        else
            raise NovelLangSyntaxError, 'SyntaxError: fail token unget' if @before_scan.nil?
            @sc.string = @before_scan
            #p @sc
        end
        p 'unget_token' if @debug
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
