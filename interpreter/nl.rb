require "strscan"
require "optparse"

class NovelLangSyntaxError < StandardError
end

class NovelLang
    @@KEYWORDS = {
        "+" => :add,
        "-" => :sub,
        "*" => :mul,
        "/" => :div,
        "(" => :parn_l,
        ")" => :parn_r,
    }

    @@KEYS = {
        "🤔" => :if,
        "🕑" => :loop,
        "⛄" => :calc,
        "📝" => :std_in,
        "「" => :std_out_L,
        "」" => :std_out_R,
        "【" => :var_L,
        "】" => :var_R,
        "（" => :ins_L,
        "）" => :ins_R,
        "……" => :section,
        ">" => :greater_than,
        "<" => :less_than,
    }
    @@KEYS_RE = "[🤔🕑⛄📝「」【】（）><]|……"
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
        p run(code)
    end

    private def run(text)
        p text if @debug

        #文字がなかったときに入力を促すわよ！
        if text.nil?
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
            end
        else
            return exp
        end
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
        if token =~ /\d+/ #トークンがリテラルか
            result = token.to_f() #リテラル
        elsif token == :parn_l
            result = expression()
            get_token() # 閉じカッコを取り除く（使用しない）
        else
            raise NovelLangSyntaxError, "Syntax error"
        end
        p result if @debug
        return result
    end

    def parse()
        expression()
    end

    #-- util --
    # token操作
    def get_token()
        if @sc.scan(/\d+|[\+\-\*\/\(\)]/) #数字or演算子
            if @sc[0] =~ /[\+\-\*\/\(\)]/ #符号
                return @@KEYWORDS[@sc[0]]
            else
                return @sc[0]
            end
        end
    end

    # def get_token()
    #     if @sc.scan(@@TOKEN_RE) #対応する文字
    #         if @sc[0] =~ /#{@@KEYS_RE}/
    #             return @@KEYS_RE[@sc[0]]
    #         elsif @sc[0] =~ /#{@@RETURN_RE}/
    #             return :return
    #         else
    #             return @sc[0]
    #         end
    #     end
    # end

    def unget_token()
        @sc.unscan() unless @sc.eos?
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
