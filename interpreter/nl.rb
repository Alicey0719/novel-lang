require "strscan"
require "optparse"
require "./utils/calc.rb"

class NovelLangSyntaxError < StandardError
end

class NovelLang
    @@KEYS = {
        '🤔' => :if,
        '🕑' => :loop,
        '⛄' => :calc,
        '📝' => :std_in,
        '「' => :std_out_L,
        '」' => :std_out_R,
        '【' => :var_L,
        '】' => :var_R,
        '（' => :ins_L,
        '）' => :ins_R,
        '……' => :section,
        '>' => :greater_than,
        '<' => :less_than,
    }
    @@KEYS_RE = '[🤔🕑⛄📝「」【】（）><]|……'
    @@RETURN_RE = '\n|\r\n'
    @@STR_RE = '[\w\p{Hiragana}\p{Katakana}\p{Han}]+'
    @@CALC_RE = '[\+\-\*\/\(\)]'

    @@TOKEN_RE = "#{RETURN_RE}|#{KEYS_RE}|#{CALC_RE}|#{STR_RE}"

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

    private def run(code)
        p code if @debug
        #code.gsub!(/[\S\N]/, '') #コメントを除く

        @sc = StringScanner.new(code)

    end


    #-- util --
    # token操作
    def get_token()
        if @sc.scan(@@TOKEN_RE) then #対応する文字
            if @sc[0] =~ /#{@@KEYS_RE}/ then
                return @@KEYS_RE[@sc[0]]
            elsif @sc[0] =~ /#{@@RETURN_RE}/ then
                return :return
            else
                return @sc[0]
            end
        end
    end

    def unget_token()
        @sc.unscan() unless @sc.eos?
    end

    # 算術演算のテキストをClacに放り込むやつ
    private def calc(text)
        c = Clac.new
        return c.run(text)
    end

    # read file2txt
    private def read_file(file_path)
        if file_path.nil? then 
            print("You need to specify the file to open.\n")
            exit 1
        end
        begin
            f = open(file_path, 'r')
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
    private def escape(code=0)
        exit(code)
    end
end

NovelLang.new()