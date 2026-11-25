" Basic highlighting for Omelette, for when the language server is not running. The
" server's semantic tokens draw over it once it is.
if exists("b:current_syntax")
  finish
endif

syntax keyword omeletteKeyword let pub fn if then else match with when type lua to
syntax keyword omeletteOperatorWord and or not
syntax keyword omeletteBoolean true false
syntax keyword omeletteNil nil
syntax match omeletteConstructor "\<\u\w*\>"
syntax match omeletteNumber "\<\d\+\(\.\d\+\)\?\>"
syntax match omeletteOperator "|>\|->\|=>\|<-\|\.\.\|[-+*/%#<>=~]"
syntax region omeletteString start=+"+ skip=+\\.+ end=+"+ oneline
syntax match omeletteComment "--.*$" contains=@Spell

highlight default link omeletteKeyword Statement
highlight default link omeletteOperatorWord Statement
highlight default link omeletteBoolean Constant
highlight default link omeletteNil Constant
highlight default link omeletteConstructor Constant
highlight default link omeletteNumber Number
highlight default link omeletteOperator Operator
highlight default link omeletteString String
highlight default link omeletteComment Comment

let b:current_syntax = "omelette"
