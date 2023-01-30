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
        "🤔" => :branch,
        "🕑" => :loop,
        "⛄" => :string,
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
        "Ex-iT" => :exit,
    }
    @@KEYS_RE = "#{@@KEYS.map { |t| Regexp.escape(t[0]) }.join("|")}"
    #@@KEYS_RE = "[🤔🕑⛄📝「」【】（）><]|……"
    @@RETURN_RE = '\n|\r\n'
    @@STR_RE = '[\w\p{Hiragana}\p{Katakana}\p{Han}]+'
    @@CALC_RE = '[\+\-\*\/\(\)]'
    @@EOP_RE = '\A\s*\z'
    @@FLOAT_STR = '\A[0-9]+\.[0-9]+\z'

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
    end

    private def run(text)
        p text if @debug

        text = text.gsub(/[\r\n]/, "")
        p text if @debug

        @sc = StringScanner.new(text)
        code_array = parse()

        print "\n" if @debug
        pp code_array if @debug
        print "\n" if @debug

        eval(code_array)
        p @nl_var_hash if @debug
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
        elsif ret = branch()
            p "Sentence branch: [#{ret}]" if @debug
            return ret
        elsif ret = loopers()
            p "Sentence loopers: [#{ret}]" if @debug
            return ret
        elsif ret = ex_it()
            p "Sentence ex-it: [#{ret}]" if @debug
            return ret
        else
            raise NovelLangSyntaxError, "Sentence Error: [#{ret}] 該当するSentenceがありません"
        end
    end

    private def loopers()
        result = [:loop]
        unless get_token() == :loop
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end

        unless ret = expression() #条件式
            raise NovelLangSyntaxError, "loop Error: not found [Expression]"
        end
        result.push(ret)

        unless get_token() == :section
            raise NovelLangSyntaxError, "loop Error: not found '……' "
        end

        unless ret = sentence() #ループ内容
            #raise NovelLangSyntaxError, "loop Error: not found []"
        end
        result.push(ret)
    end    

    private def branch()
        result = [:branch]
        unless get_token() == :branch
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end
        unless ret = expression() #条件式
            raise NovelLangSyntaxError, "branch Error: not found [Expression]"
        end
        result.push(ret)

        unless get_token() == :section
            raise NovelLangSyntaxError, "branch Error: not found '……' "
        end

        unless ret = sentence() #真のとき
            #raise NovelLangSyntaxError, "branch Error: not found []"
        end
        result.push(ret)

        unless get_token() == :section
            raise NovelLangSyntaxError, "branch Error: not found '……' "
        end

        unless ret = sentence() #偽のとき
            #raise NovelLangSyntaxError, "branch Error: not found []"
        end
        result.push(ret)
    end

    private def std_out()
        result = [:std_out]
        unless get_token() == :std_out_L
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end

        unless ret = expression()
            raise NovelLangSyntaxError, "STD_OUT Error: not found [Expression]"
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

    private def ex_it()
        unless get_token() == :exit
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end
        return :exit
    end

    private def assignment()
        result = [:assignment]
        unless get_token() == :var_L
            unget_token()
            return nil
            #raise NovelLangSyntaxError, "AssignmentError: not found '【' "
        end

        ret = get_token() #String(変数名)が帰ってくるはず
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

        ret = get_token()
        #std_in(何もしない)か式か文字列が代入されるはず
        if ret == :string then #文字列
            ret = get_token()
            raise NovelLangSyntaxError, "AssignmentError: not found [⛄]" unless get_token() == :string
        elsif ret != :std_in then #式のときの処理
            unget_token() #expでget_tokenするため一旦ungetする
            unless ret = expression()
                raise NovelLangSyntaxError, "AssignmentError: not found [Expression]"
            end
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
                # addは文字列加算OK
                begin
                    return eval(exp[1]) + eval(exp[2])
                rescue TypeError => e
                    return eval(exp[1]).to_s + eval(exp[2]).to_s
                end
            when :sub
                tmp1 = eval(exp[1])
                str_is_exception(tmp1)
                tmp2 = eval(exp[2])
                str_is_exception(tmp2)
                return tmp1 - tmp2
            when :mul
                tmp1 = eval(exp[1])
                str_is_exception(tmp1)
                tmp2 = eval(exp[2])
                str_is_exception(tmp2)
                return tmp1 * tmp2
            when :div
                tmp1 = eval(exp[1])
                str_is_exception(tmp1)
                tmp2 = eval(exp[2])
                str_is_exception(tmp2)
                raise NovelLangSyntaxError, "Division by zero error" if tmp2 == 0 #ゼロ除算エラーわよ
                return tmp1 / tmp2
            when :assignment
                #p "a  #{exp}"
                return @nl_var_hash[eval(exp[1][1])] = eval(exp[2])
            when :var
                #p "var-eval #{exp} #{@nl_var_hash[exp[1]]}"
                return @nl_var_hash[exp[1]]
            when :std_out                
                print "#{eval(exp[1])}\n"
                p "#{eval(exp[1]).class}" if @debug
            when :branch
                f = eval(exp[1]).to_i
                if f.positive? then
                    return eval(exp[2])
                else
                    return eval(exp[3])
                end
            when :loop
                while true do
                    f = eval(exp[1]).to_i
                    unless f.positive? then
                        break
                    end
                    eval(exp[2])
                end
                return true
            end
        elsif exp == :std_in
            tmp = STDIN.gets.chomp
            if is_number?(tmp)
                return tmp.to_f if tmp =~ /#{@@FLOAT_STR}/
                return tmp.to_i
            end
            return tmp
        elsif exp == :exit
            escape(0)
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
        
        unget_token() 

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
        
        unget_token()
        p "term: #{result}" if @debug
        return result
    end

    ## Fact
    private def factor()
        token = get_token()
        if token =~ /\d+/ #トークンがリテラルか
            #リテラル
            result = token.to_i
            result = token.to_f if token =~ /#{@@FLOAT_STR}/ 
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

    # 文字列が数字のみならTrue
    private def is_number?(str)
        nil != (str =~ /\A[0-9.]+\z/)
    end

    # stringがきたらexception
    private def str_is_exception(a)
        if a.is_a?(String)
            raise NovelLangSyntaxError, "Unexpected type error: string "
        end 
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
