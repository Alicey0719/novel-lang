require "strscan"
require "optparse"
require "./utils/calc.rb"

class NovelLangSyntaxError < StandardError
end

class NovelLang
    def initialize
        # init
        STDOUT.sync = true
        STDIN.sync = true

        # option-parse
        op = OptionParser.new
        op.on("-d", "--debug", desk = "Debug mode.") { |v| @debug = true }
        op.parse!(ARGV)

        code = read_file(ARGV[0])
        run(code)
    end

    private def run(code)
        p code if @debug
        #code.gsub!(/[\S\N]/, '') #コメントを除く

        @sc = StringScanner.new(code)


    end
    
    

    #-- util --
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