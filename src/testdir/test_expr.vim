" Tests for expressions.

source check.vim

func Test_equal()
  let base = {}
  func base.method()
    return 1
  endfunc
  func base.other() dict
    return 1
  endfunc
  let instance = copy(base)
  call assert_true(base.method == instance.method)
  call assert_true([base.method] == [instance.method])
  call assert_true(base.other == instance.other)
  call assert_true([base.other] == [instance.other])

  call assert_false(base.method == base.other)
  call assert_false([base.method] == [base.other])
  call assert_false(base.method == instance.other)
  call assert_false([base.method] == [instance.other])

  call assert_fails('echo base.method > instance.method')
  call assert_equal(0, test_null_function() == function('min'))
  call assert_equal(1, test_null_function() == test_null_function())
  call assert_fails('eval 10 == test_unknown()', 'E685:')
endfunc

func Test_version()
  call assert_true(has('patch-7.4.001'))
  call assert_true(has('patch-7.4.01'))
  call assert_true(has('patch-7.4.1'))
  call assert_true(has('patch-6.9.999'))
  call assert_true(has('patch-7.1.999'))
  call assert_true(has('patch-7.4.123'))

  call assert_false(has('patch-7'))
  call assert_false(has('patch-7.4'))
  call assert_false(has('patch-7.4.'))
  call assert_false(has('patch-9.1.0'))
  call assert_false(has('patch-9.9.1'))
endfunc

func Test_op_trinary()
  call assert_equal('yes', 1 ? 'yes' : 'no')
  call assert_equal('no', 0 ? 'yes' : 'no')
  call assert_equal('no', 'x' ? 'yes' : 'no')
  call assert_equal('yes', '1x' ? 'yes' : 'no')

  call assert_fails('echo [1] ? "yes" : "no"', 'E745:')
  call assert_fails('echo {} ? "yes" : "no"', 'E728:')
endfunc

func Test_op_falsy()
  call assert_equal(v:true, v:true ?? 456)
  call assert_equal(123, 123 ?? 456)
  call assert_equal('yes', 'yes' ?? 456)
  call assert_equal(0z00, 0z00 ?? 456)
  call assert_equal([1], [1] ?? 456)
  call assert_equal(#{one: 1}, #{one: 1} ?? 456)
  if has('float')
    call assert_equal(0.1, 0.1 ?? 456)
  endif

  call assert_equal(456, v:false ?? 456)
  call assert_equal(456, 0 ?? 456)
  call assert_equal(456, '' ?? 456)
  call assert_equal(456, 0z ?? 456)
  call assert_equal(456, [] ?? 456)
  call assert_equal(456, {} ?? 456)
  if has('float')
    call assert_equal(456, 0.0 ?? 456)
  endif
endfunc

func Test_dict()
  let d = {'': 'empty', 'a': 'a', 0: 'zero'}
  call assert_equal('empty', d[''])
  call assert_equal('a', d['a'])
  call assert_equal('zero', d[0])
  call assert_true(has_key(d, ''))
  call assert_true(has_key(d, 'a'))
  call assert_fails("let i = has_key([], 'a')", 'E715:')

  let d[''] = 'none'
  let d['a'] = 'aaa'
  call assert_equal('none', d[''])
  call assert_equal('aaa', d['a'])

  let d[ 'b' ] = 'bbb'
  call assert_equal('bbb', d[ 'b' ])
endfunc

func Test_strgetchar()
  call assert_equal(char2nr('a'), strgetchar('axb', 0))
  call assert_equal(char2nr('x'), 'axb'->strgetchar(1))
  call assert_equal(char2nr('b'), strgetchar('axb', 2))

  call assert_equal(-1, strgetchar('axb', -1))
  call assert_equal(-1, strgetchar('axb', 3))
  call assert_equal(-1, strgetchar('', 0))
  call assert_fails("let c=strgetchar([], 1)", 'E730:')
  call assert_fails("let c=strgetchar('axb', [])", 'E745:')
endfunc

func Test_strcharpart()
  call assert_equal('a', strcharpart('axb', 0, 1))
  call assert_equal('x', 'axb'->strcharpart(1, 1))
  call assert_equal('b', strcharpart('axb', 2, 1))
  call assert_equal('xb', strcharpart('axb', 1))

  call assert_equal('', strcharpart('axb', 1, 0))
  call assert_equal('', strcharpart('axb', 1, -1))
  call assert_equal('', strcharpart('axb', -1, 1))
  call assert_equal('', strcharpart('axb', -2, 2))

  call assert_equal('a', strcharpart('axb', -1, 2))

  call assert_equal('edit', "editor"[-10:3])
endfunc

func Test_getreg_empty_list()
  call assert_equal('', getreg('x'))
  call assert_equal([], getreg('x', 1, 1))
  let x = getreg('x', 1, 1)
  let y = x
  call add(x, 'foo')
  call assert_equal(['foo'], y)
  call assert_fails('call getreg([])', 'E730:')
endfunc

func Test_loop_over_null_list()
  let null_list = test_null_list()
  for i in null_list
    call assert_report('should not get here')
  endfor
endfunc

func Test_setreg_null_list()
  call setreg('x', test_null_list())
endfunc

func Test_special_char()
  " The failure is only visible using valgrind.
  call assert_fails('echo "\<C-">')
endfunc

func Test_method_with_prefix()
  call assert_equal(1, !range(5)->empty())
  call assert_equal([0, 1, 2], --3->range())
  call assert_equal(0, !-3)
  call assert_equal(1, !+-+0)
endfunc

func Test_option_value()
  " boolean
  set bri
  call assert_equal(1, &bri)
  set nobri
  call assert_equal(0, &bri)

  " number
  set ts=1
  call assert_equal(1, &ts)
  set ts=8
  call assert_equal(8, &ts)

  " string
  exe "set cedit=\<Esc>"
  call assert_equal("\<Esc>", &cedit)
  set cpo=
  call assert_equal("", &cpo)
  set cpo=abcdefgi
  call assert_equal("abcdefgi", &cpo)
  set cpo&vim
endfunc

function Test_printf_misc()
  call assert_equal('123', printf('123'))
  call assert_fails("call printf('123', 3)", "E767:")

  call assert_equal('123', printf('%d', 123))
  call assert_equal('123', printf('%i', 123))
  call assert_equal('123', printf('%D', 123))
  call assert_equal('123', printf('%U', 123))
  call assert_equal('173', printf('%o', 123))
  call assert_equal('173', printf('%O', 123))
  call assert_equal('7b', printf('%x', 123))
  call assert_equal('7B', printf('%X', 123))

  call assert_equal('123', printf('%hd', 123))
  call assert_equal('-123', printf('%hd', -123))
  call assert_equal('-1', printf('%hd', 0xFFFF))
  call assert_equal('-1', printf('%hd', 0x1FFFFF))

  call assert_equal('123', printf('%hu', 123))
  call assert_equal('65413', printf('%hu', -123))
  call assert_equal('65535', printf('%hu', 0xFFFF))
  call assert_equal('65535', printf('%hu', 0x1FFFFF))

  call assert_equal('123', printf('%ld', 123))
  call assert_equal('-123', printf('%ld', -123))
  call assert_equal('65535', printf('%ld', 0xFFFF))
  call assert_equal('131071', printf('%ld', 0x1FFFF))

  if has('ebcdic')
    call assert_equal('#', printf('%c', 123))
  else
    call assert_equal('{', printf('%c', 123))
  endif
  call assert_equal('abc', printf('%s', 'abc'))
  call assert_equal('abc', printf('%S', 'abc'))

  call assert_equal('+123', printf('%+d', 123))
  call assert_equal('-123', printf('%+d', -123))
  call assert_equal('+123', printf('%+ d', 123))
  call assert_equal(' 123', printf('% d', 123))
  call assert_equal(' 123', printf('%  d', 123))
  call assert_equal('-123', printf('% d', -123))

  call assert_equal('123', printf('%2d', 123))
  call assert_equal('   123', printf('%6d', 123))
  call assert_equal('000123', printf('%06d', 123))
  call assert_equal('+00123', printf('%+06d', 123))
  call assert_equal(' 00123', printf('% 06d', 123))
  call assert_equal('  +123', printf('%+6d', 123))
  call assert_equal('   123', printf('% 6d', 123))
  call assert_equal('  -123', printf('% 6d', -123))

  " Test left adjusted.
  call assert_equal('123   ', printf('%-6d', 123))
  call assert_equal('+123  ', printf('%-+6d', 123))
  call assert_equal(' 123  ', printf('%- 6d', 123))
  call assert_equal('-123  ', printf('%- 6d', -123))

  call assert_equal('  00123', printf('%7.5d', 123))
  call assert_equal(' -00123', printf('%7.5d', -123))
  call assert_equal(' +00123', printf('%+7.5d', 123))
  " Precision field should not be used when combined with %0
  call assert_equal('  00123', printf('%07.5d', 123))
  call assert_equal(' -00123', printf('%07.5d', -123))

  call assert_equal('  123', printf('%*d', 5, 123))
  call assert_equal('123  ', printf('%*d', -5, 123))
  call assert_equal('00123', printf('%.*d', 5, 123))
  call assert_equal('  123', printf('% *d', 5, 123))
  call assert_equal(' +123', printf('%+ *d', 5, 123))

  call assert_equal('foobar', printf('%.*s',  9, 'foobar'))
  call assert_equal('foo',    printf('%.*s',  3, 'foobar'))
  call assert_equal('',       printf('%.*s',  0, 'foobar'))
  call assert_equal('foobar', printf('%.*s', -1, 'foobar'))

  " Simple quote (thousand grouping char) is ignored.
  call assert_equal('+00123456', printf("%+'09d", 123456))

  " Unrecognized format specifier kept as-is.
  call assert_equal('_123', printf("%_%d", 123))

  " Test alternate forms.
  call assert_equal('0x7b', printf('%#x', 123))
  call assert_equal('0X7B', printf('%#X', 123))
  call assert_equal('0173', printf('%#o', 123))
  call assert_equal('0173', printf('%#O', 123))
  call assert_equal('abc', printf('%#s', 'abc'))
  call assert_equal('abc', printf('%#S', 'abc'))
  call assert_equal('  0173', printf('%#6o', 123))
  call assert_equal(' 00173', printf('%#6.5o', 123))
  call assert_equal('  0173', printf('%#6.2o', 123))
  call assert_equal('  0173', printf('%#6.2o', 123))
  call assert_equal('0173', printf('%#2.2o', 123))

  call assert_equal(' 00123', printf('%6.5d', 123))
  call assert_equal(' 0007b', printf('%6.5x', 123))

  call assert_equal('123', printf('%.2d', 123))
  call assert_equal('0123', printf('%.4d', 123))
  call assert_equal('0000000123', printf('%.10d', 123))
  call assert_equal('123', printf('%.0d', 123))

  call assert_equal('abc', printf('%2s', 'abc'))
  call assert_equal('abc', printf('%2S', 'abc'))
  call assert_equal('abc', printf('%.4s', 'abc'))
  call assert_equal('abc', printf('%.4S', 'abc'))
  call assert_equal('ab', printf('%.2s', 'abc'))
  call assert_equal('ab', printf('%.2S', 'abc'))
  call assert_equal('', printf('%.0s', 'abc'))
  call assert_equal('', printf('%.s', 'abc'))
  call assert_equal(' abc', printf('%4s', 'abc'))
  call assert_equal(' abc', printf('%4S', 'abc'))
  call assert_equal('0abc', printf('%04s', 'abc'))
  call assert_equal('0abc', printf('%04S', 'abc'))
  call assert_equal('abc ', printf('%-4s', 'abc'))
  call assert_equal('abc ', printf('%-4S', 'abc'))

  call assert_equal('🐍', printf('%.2S', '🐍🐍'))
  call assert_equal('', printf('%.1S', '🐍🐍'))

  call assert_equal('1%', printf('%d%%', 1))
endfunc

function Test_printf_float()
  if has('float')
    call assert_equal('1.000000', printf('%f', 1))
    call assert_equal('1.230000', printf('%f', 1.23))
    call assert_equal('1.230000', printf('%F', 1.23))
    call assert_equal('9999999.9', printf('%g', 9999999.9))
    call assert_equal('9999999.9', printf('%G', 9999999.9))
    call assert_equal('1.00000001e7', printf('%.8g', 10000000.1))
    call assert_equal('1.00000001E7', printf('%.8G', 10000000.1))
    call assert_equal('1.230000e+00', printf('%e', 1.23))
    call assert_equal('1.230000E+00', printf('%E', 1.23))
    call assert_equal('1.200000e-02', printf('%e', 0.012))
    call assert_equal('-1.200000e-02', printf('%e', -0.012))
    call assert_equal('0.33', printf('%.2f', 1.0/3.0))
    call assert_equal('  0.33', printf('%6.2f', 1.0/3.0))
    call assert_equal(' -0.33', printf('%6.2f', -1.0/3.0))
    call assert_equal('000.33', printf('%06.2f', 1.0/3.0))
    call assert_equal('-00.33', printf('%06.2f', -1.0/3.0))
    call assert_equal('-00.33', printf('%+06.2f', -1.0/3.0))
    call assert_equal('+00.33', printf('%+06.2f', 1.0/3.0))
    call assert_equal(' 00.33', printf('% 06.2f', 1.0/3.0))
    call assert_equal('000.33', printf('%06.2g', 1.0/3.0))
    call assert_equal('-00.33', printf('%06.2g', -1.0/3.0))
    call assert_equal('0.33', printf('%3.2f', 1.0/3.0))
    call assert_equal('003.33e-01', printf('%010.2e', 1.0/3.0))
    call assert_equal(' 03.33e-01', printf('% 010.2e', 1.0/3.0))
    call assert_equal('+03.33e-01', printf('%+010.2e', 1.0/3.0))
    call assert_equal('-03.33e-01', printf('%010.2e', -1.0/3.0))

    " When precision is 0, the dot should be omitted.
    call assert_equal('  2', printf('%3.f', 7.0/3.0))
    call assert_equal('  2', printf('%3.g', 7.0/3.0))
    call assert_equal('  2e+00', printf('%7.e', 7.0/3.0))

    " Float zero can be signed.
    call assert_equal('+0.000000', printf('%+f', 0.0))
    call assert_equal('0.000000', printf('%f', 1.0/(1.0/0.0)))
    call assert_equal('-0.000000', printf('%f', 1.0/(-1.0/0.0)))
    call assert_equal('0.0', printf('%s', 1.0/(1.0/0.0)))
    call assert_equal('-0.0', printf('%s', 1.0/(-1.0/0.0)))
    call assert_equal('0.0', printf('%S', 1.0/(1.0/0.0)))
    call assert_equal('-0.0', printf('%S', 1.0/(-1.0/0.0)))

    " Float infinity can be signed.
    call assert_equal('inf', printf('%f', 1.0/0.0))
    call assert_equal('-inf', printf('%f', -1.0/0.0))
    call assert_equal('inf', printf('%g', 1.0/0.0))
    call assert_equal('-inf', printf('%g', -1.0/0.0))
    call assert_equal('inf', printf('%e', 1.0/0.0))
    call assert_equal('-inf', printf('%e', -1.0/0.0))
    call assert_equal('INF', printf('%F', 1.0/0.0))
    call assert_equal('-INF', printf('%F', -1.0/0.0))
    call assert_equal('INF', printf('%E', 1.0/0.0))
    call assert_equal('-INF', printf('%E', -1.0/0.0))
    call assert_equal('INF', printf('%E', 1.0/0.0))
    call assert_equal('-INF', printf('%G', -1.0/0.0))
    call assert_equal('+inf', printf('%+f', 1.0/0.0))
    call assert_equal('-inf', printf('%+f', -1.0/0.0))
    call assert_equal(' inf', printf('% f',  1.0/0.0))
    call assert_equal('   inf', printf('%6f', 1.0/0.0))
    call assert_equal('  -inf', printf('%6f', -1.0/0.0))
    call assert_equal('   inf', printf('%6g', 1.0/0.0))
    call assert_equal('  -inf', printf('%6g', -1.0/0.0))
    call assert_equal('  +inf', printf('%+6f', 1.0/0.0))
    call assert_equal('   inf', printf('% 6f', 1.0/0.0))
    call assert_equal('  +inf', printf('%+06f', 1.0/0.0))
    call assert_equal('inf   ', printf('%-6f', 1.0/0.0))
    call assert_equal('-inf  ', printf('%-6f', -1.0/0.0))
    call assert_equal('+inf  ', printf('%-+6f', 1.0/0.0))
    call assert_equal(' inf  ', printf('%- 6f', 1.0/0.0))
    call assert_equal('-INF  ', printf('%-6F', -1.0/0.0))
    call assert_equal('+INF  ', printf('%-+6F', 1.0/0.0))
    call assert_equal(' INF  ', printf('%- 6F', 1.0/0.0))
    call assert_equal('INF   ', printf('%-6G', 1.0/0.0))
    call assert_equal('-INF  ', printf('%-6G', -1.0/0.0))
    call assert_equal('INF   ', printf('%-6E', 1.0/0.0))
    call assert_equal('-INF  ', printf('%-6E', -1.0/0.0))
    call assert_equal('inf', printf('%s', 1.0/0.0))
    call assert_equal('-inf', printf('%s', -1.0/0.0))

    " Test special case where max precision is truncated at 340.
    call assert_equal('1.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', printf('%.330f', 1.0))
    call assert_equal('1.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', printf('%.340f', 1.0))
    call assert_equal('1.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', printf('%.350f', 1.0))

    " Float nan (not a number) has no sign.
    call assert_equal('nan', printf('%f', sqrt(-1.0)))
    call assert_equal('nan', printf('%f', 0.0/0.0))
    call assert_equal('nan', printf('%f', -0.0/0.0))
    call assert_equal('nan', printf('%g', 0.0/0.0))
    call assert_equal('nan', printf('%e', 0.0/0.0))
    call assert_equal('NAN', printf('%F', 0.0/0.0))
    call assert_equal('NAN', printf('%G', 0.0/0.0))
    call assert_equal('NAN', printf('%E', 0.0/0.0))
    call assert_equal('NAN', printf('%F', -0.0/0.0))
    call assert_equal('NAN', printf('%G', -0.0/0.0))
    call assert_equal('NAN', printf('%E', -0.0/0.0))
    call assert_equal('   nan', printf('%6f', 0.0/0.0))
    call assert_equal('   nan', printf('%06f', 0.0/0.0))
    call assert_equal('nan   ', printf('%-6f', 0.0/0.0))
    call assert_equal('nan   ', printf('%- 6f', 0.0/0.0))
    call assert_equal('nan', printf('%s', 0.0/0.0))
    call assert_equal('nan', printf('%s', -0.0/0.0))
    call assert_equal('nan', printf('%S', 0.0/0.0))
    call assert_equal('nan', printf('%S', -0.0/0.0))

    call assert_fails('echo printf("%f", "a")', 'E807:')
  endif
endfunc

function Test_printf_errors()
  call assert_fails('echo printf("%d", {})', 'E728:')
  call assert_fails('echo printf("%d", [])', 'E745:')
  call assert_fails('echo printf("%d", 1, 2)', 'E767:')
  call assert_fails('echo printf("%*d", 1)', 'E766:')
  call assert_fails('echo printf("%s")', 'E766:')
  if has('float')
    call assert_fails('echo printf("%d", 1.2)', 'E805:')
    call assert_fails('echo printf("%f")')
  endif
endfunc

function Test_max_min_errors()
  call assert_fails('call max(v:true)', 'E712:')
  call assert_fails('call max(v:true)', 'max()')
  call assert_fails('call min(v:true)', 'E712:')
  call assert_fails('call min(v:true)', 'min()')
endfunc

function Test_printf_64bit()
  call assert_equal("123456789012345", printf('%d', 123456789012345))
endfunc

function Test_printf_spec_s()
  " number
  call assert_equal("1234567890", printf('%s', 1234567890))

  " string
  call assert_equal("abcdefgi", printf('%s', "abcdefgi"))

  " float
  if has('float')
    call assert_equal("1.23", printf('%s', 1.23))
  endif

  " list
  let value = [1, 'two', ['three', 4]]
  call assert_equal(string(value), printf('%s', value))

  " dict
  let value = {'key1' : 'value1', 'key2' : ['list', 'value'], 'key3' : {'dict' : 'value'}}
  call assert_equal(string(value), printf('%s', value))

  " funcref
  call assert_equal('printf', printf('%s', 'printf'->function()))

  " partial
  call assert_equal(string(function('printf', ['%s'])), printf('%s', function('printf', ['%s'])))
endfunc

function Test_printf_spec_b()
  call assert_equal("0", printf('%b', 0))
  call assert_equal("00001100", printf('%08b', 12))
  call assert_equal("11111111", printf('%08b', 0xff))
  call assert_equal("   1111011", printf('%10b', 123))
  call assert_equal("0001111011", printf('%010b', 123))
  call assert_equal(" 0b1111011", printf('%#10b', 123))
  call assert_equal("0B01111011", printf('%#010B', 123))
  call assert_equal("1001001100101100000001011010010", printf('%b', 1234567890))
  call assert_equal("11100000100100010000110000011011101111101111001", printf('%b', 123456789012345))
  call assert_equal("1111111111111111111111111111111111111111111111111111111111111111", printf('%b', -1))
endfunc

func Test_function_with_funcref()
  let s:f = function('type')
  let s:fref = function(s:f)
  call assert_equal(v:t_string, s:fref('x'))
  call assert_fails("call function('s:f')", 'E700:')

  call assert_fails("call function('foo()')", 'E475:')
  call assert_fails("call function('foo()')", 'foo()')
  call assert_fails("function('')", 'E129:')
endfunc

func Test_funcref()
  func! One()
    return 1
  endfunc
  let OneByName = function('One')
  let OneByRef = funcref('One')
  func! One()
    return 2
  endfunc
  call assert_equal(2, OneByName())
  call assert_equal(1, OneByRef())
  let OneByRef = 'One'->funcref()
  call assert_equal(2, OneByRef())
  call assert_fails('echo funcref("{")', 'E475:')
  let OneByRef = funcref("One", repeat(["foo"], 20))
  call assert_fails('let OneByRef = funcref("One", repeat(["foo"], 21))', 'E118:')
  call assert_fails('echo function("min") =~ function("min")', 'E694:')
  call assert_fails('echo test_null_function()->funcref()', 'E475: Invalid argument: NULL')
endfunc

func Test_setmatches()
  hi def link 1 Comment
  hi def link 2 PreProc
  let set = [{"group": 1, "pattern": 2, "id": 3, "priority": 4}]
  let exp = [{"group": '1', "pattern": '2', "id": 3, "priority": 4}]
  if has('conceal')
    let set[0]['conceal'] = 5
    let exp[0]['conceal'] = '5'
  endif
  eval set->setmatches()
  call assert_equal(exp, getmatches())
  call assert_fails('let m = setmatches([], [])', 'E745:')
endfunc

func Test_empty_concatenate()
  call assert_equal('b', 'a'[4:0] . 'b')
  call assert_equal('b', 'b' . 'a'[4:0])
endfunc

func Test_broken_number()
  let X = 'bad'
  call assert_fails('echo 1X', 'E15:')
  call assert_fails('echo 0b1X', 'E15:')
  call assert_fails('echo 0b12', 'E15:')
  call assert_fails('echo 0x1X', 'E15:')
  call assert_fails('echo 011X', 'E15:')
  call assert_equal(2, str2nr('2a'))
  call assert_fails('inoremap <Char-0b1z> b', 'E474:')
endfunc

func Test_eval_after_if()
  let s:val = ''
  func SetVal(x)
    let s:val ..= a:x
  endfunc
  if 0 | eval SetVal('a') | endif | call SetVal('b')
  call assert_equal('b', s:val)
endfunc

" Test for command-line completion of expressions
func Test_expr_completion()
  CheckFeature cmdline_compl
  for cmd in [
	\ 'let a = ',
	\ 'const a = ',
	\ 'if',
	\ 'elseif',
	\ 'while',
	\ 'for',
	\ 'echo',
	\ 'echon',
	\ 'execute',
	\ 'echomsg',
	\ 'echoerr',
	\ 'call',
	\ 'return',
	\ 'cexpr',
	\ 'caddexpr',
	\ 'cgetexpr',
	\ 'lexpr',
	\ 'laddexpr',
	\ 'lgetexpr']
    call feedkeys(":" . cmd . " getl\<Tab>\<Home>\"\<CR>", 'xt')
    call assert_equal('"' . cmd . ' getline(', getreg(':'))
  endfor

  " completion for the expression register
  call feedkeys(":\"\<C-R>=float2\t\"\<C-B>\"\<CR>", 'xt')
  call assert_equal('"float2nr("', @=)

  " completion for window local variables
  let w:wvar1 = 10
  let w:wvar2 = 10
  call feedkeys(":echo w:wvar\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"echo w:wvar1 w:wvar2', @:)
  unlet w:wvar1 w:wvar2

  " completion for tab local variables
  let t:tvar1 = 10
  let t:tvar2 = 10
  call feedkeys(":echo t:tvar\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"echo t:tvar1 t:tvar2', @:)
  unlet t:tvar1 t:tvar2

  " completion for variables
  let g:tvar1 = 1
  let g:tvar2 = 2
  call feedkeys(":let g:tv\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"let g:tvar1 g:tvar2', @:)
  " completion for variables after a ||
  call feedkeys(":echo 1 || g:tv\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"echo 1 || g:tvar1 g:tvar2', @:)

  " completion for options
  call feedkeys(":echo &compat\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"echo &compatible', @:)
  call feedkeys(":echo 1 && &compat\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"echo 1 && &compatible', @:)
  call feedkeys(":echo &g:equala\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"echo &g:equalalways', @:)

  " completion for string
  call feedkeys(":echo \"Hello\\ World\"\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal("\"echo \"Hello\\ World\"\<C-A>", @:)
  call feedkeys(":echo 'Hello World'\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal("\"echo 'Hello World'\<C-A>", @:)

  " completion for command after a |
  call feedkeys(":echo 'Hello' | cwin\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal("\"echo 'Hello' | cwindow", @:)

  " completion for environment variable
  let $X_VIM_TEST_COMPLETE_ENV = 'foo'
  call feedkeys(":let $X_VIM_TEST_COMPLETE_E\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_match('"let $X_VIM_TEST_COMPLETE_ENV', @:)
  unlet $X_VIM_TEST_COMPLETE_ENV
endfunc

" Test for errors in expression evaluation
func Test_expr_eval_error()
  call assert_fails("let i = 'abc' . []", 'E730:')
  call assert_fails("let l = [] + 10", 'E745:')
  call assert_fails("let v = 10 + []", 'E745:')
  call assert_fails("let v = 10 / []", 'E745:')
  call assert_fails("let v = -{}", 'E728:')
endfunc

func Test_white_in_function_call()
  let text = substitute ( 'some text' , 't' , 'T' , 'g' )
  call assert_equal('some TexT', text)
endfunc

" Test for float value comparison
func Test_float_compare()
  CheckFeature float
  call assert_true(1.2 == 1.2)
  call assert_true(1.0 != 1.2)
  call assert_true(1.2 > 1.0)
  call assert_true(1.2 >= 1.2)
  call assert_true(1.0 < 1.2)
  call assert_true(1.2 <= 1.2)
  call assert_true(+0.0 == -0.0)
  " two NaNs (not a number) are not equal
  call assert_true(sqrt(-4.01) != (0.0 / 0.0))
  " two inf (infinity) are equal
  call assert_true((1.0 / 0) == (2.0 / 0))
  " two -inf (infinity) are equal
  call assert_true(-(1.0 / 0) == -(2.0 / 0))
  " +infinity != -infinity
  call assert_true((1.0 / 0) != -(2.0 / 0))
endfunc

" vim: shiftwidth=2 sts=2 expandtab