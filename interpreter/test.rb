require "strscan"

KEYS = {
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

KEYS_RE = '[🤔🕑⛄📝「」【】（）><]|……'
RETURN_RE = '\n|\r\n'
GEN_RE = '[\w\p{Hiragana}\p{Katakana}\p{Han}]+'
CALC_RE = '[\+\-\*\/\(\)]'

TOKEN_RE = /#{RETURN_RE}|#{KEYS_RE}|#{CALC_RE}|#{GEN_RE}/

f = open('../sample/if_samp.凸', 'r')
code = f.read
f.close

p code 

sc = StringScanner.new(code)

c = 0
while true
    break if sc.eos?
    break if c > 100

    sc.scan(TOKEN_RE)
    if sc[0] =~ /#{KEYS_RE}/ then
        #p sc[0]
        p KEYS[sc[0]]
    elsif sc[0] =~ /#{RETURN_RE}/ then
        print "\n"
    else
        p sc[0]
    end
    c+=1
end
