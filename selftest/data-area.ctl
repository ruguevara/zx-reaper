c $812E Game over
@ $812E label=GAMEOVER
t $8144 Title
@ $8144 label=TITLE
T $8144,12,11:B1
t $8150 Game over message
@ $8150 label=OVERMSG
T $8150,9,8:B1
g $8159 Player X
@ $8159 label=PX
g $815A Player Y
@ $815A label=PY
g $815B Frame counter
@ $815B label=TICK
g $815C Input bits
@ $815C label=KEYS
g $815D Countdown timer
@ $815D label=TIMER
b $815E Stack area
S $815E,64,64:$55
t $819E Top of stack; trailing text
@ $819E label=STACK
T $819E,3
i $81A1
