;Robert Lichenstein & Peter Bromley // CS390 // Ross Dining Hall Simulation
;Credits to Professor Dickerson in teaching us a lot of the stuff we did

__includes["linesfile.nls" "movementfile.nls"]

globals[
  time     ;the current time in hours/minutes/seconds
  line-length      ;the average line-length of all lines, something the turtles can see
  salad-queue ;global visible queue for the salad bar
  station-1-queue  ;global visible queue for food station 1
  station-2-queue ;global visible queue for food sation 2
  pizza-queue ;global visible queue for the pizza line
  taco-queue-1  ;global visible queue for top taco line
  taco-queue-2  ;global visible queue for bottom taco line
  max-speed   ;max speed of a student
  salad-move-sequence ;movement sequence to make a salad
  pizza-move-sequence ;movement sequence to gather pizza
  station-1-move-sequence  ;movement sequence to get food from station 1
  station-2-move-sequence    ;movement sequence to get food from station 1
  taco-move-sequence
]

turtles-own[
  restrictions     ;a student dietary restrictions
  priority         ;the student current movement priority
  mqueue           ;the priority queue of what a student needs to do
  desires          ; the desires of a student
  stations         ;queue list of food stations a student will visit
  my-seat          ; a patch to remember their seat
  tte              ;time-to-eat, abbreviated, determines how long a student takes to eat
  athlete?         ;determines if a student is an athlete
  restricted?      ;determines if a student has a dietary restriction
  in-line?         ;determines if a student is in a food line
  speed            ;the turtles current speed
  sequence         ;current movement sequence of the turtle
  sequence-ticks   ;cooldown time for each sequence move
  patience         ;determines a turtle's patience threshold (based on line length and num students in ross)
]
patches-own[
  walk?           ;is the patch walkable?
  seating?        ;is the patch a seat?
  food-type       ;used for snack/drink patches, tells us what type of stuff is being served
  salad-line      ;whether a patch is in the salad-line, or the back of the salad-line
  station-1-line  ;similar to above, info on patches in station-1-line
  station-2-line  ;similar to above, info on patches in station-2-line
  pizza-line      ;similar to above, info on patches in pizza-line
  taco-line
]

;Observer Context
;sets up our patches by:
;loading from png
;labeling the patches
;and setting up lines
to setup
  ca
  reset-ticks         ;initializes our ticks and our time
  set time 0
  ifelse not taco? [
    import-pcolors "rossdining.png"     ;imports the proper patches we have painstakingly painted
  ] [
    import-pcolors "rossdining-with-taco.png"
  ]
  label-patches                       ;labels/inits patches properly by color
  set max-speed 5.0                   ;init max turt speed
  init-salad-line                     ;inits all of the line patches below
  init-station-1-line
  init-station-2-line
  init-pizza-line
  init-taco-line

  ;the following are hardcoded movement sequences for turtles to follow to simulate
  ;gathering food from a counter top
  ;u = up, r = right, l = left
  set salad-move-sequence (list "u" "u" "u" "u" "u" "u" "u" "u" "r" "u" "r" "r" "u")
  set station-1-move-sequence (list "r" "u" "r" "r" "u" "r" "u" "r" "r" "u" "r" "r" "r")
  set station-2-move-sequence (list "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "u" "l" "l" "u" "l" "l" "u" "l" "l")
  set pizza-move-sequence (list "l" "l" "l" "l" "l" "l")
  if taco? [ set taco-move-sequence (list "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "l" "l") ]
end


;Observer Context
;our go function, everything tick based happens in here
to go
  tick
  generate-people             ;this generates people with probabilities based on
  ;swipe numbers given to us from ross dining hall
  ask turtles[
    ;here we ask all of our turtles to follow the move-students function
    ;;move students is our default movement algorithm for students not in a line
    move-students
  ]
  move-salad-queue              ;;the following functions handle movement for students in a line
  move-pizza-queue              ;;this moves up the priority queue for movement
  move-station-1-queue
  move-station-2-queue
  if taco? [
    move-taco-queue-1
    move-taco-queue-2
  ]
  move-in-sequence              ;;move-in-sequence handles what happens to a turtle popped off of a
  ;food line priority queue, and moves them through the proper steps for retrieving food
  update-time              ;update our system time
  if ticks = 12600 [         ;stop after 3.5 hours, or at 8:30 PM
    stop
  ]
end


;Observer Context
;updates our system time, turning ticks into hours/minutes/seconds
;we also update average line length here, for convenience
to update-time
  let hours floor (ticks / 3600)
  let minutes (floor ((ticks mod 3600) / 60))
  set time (word "" (5 + hours) word ":" minutes word ":" (ticks mod 60))
  set line-length ((length salad-queue + length station-1-queue + length station-2-queue + length pizza-queue) / 4)
  if taco? [ set line-length (line-length + length taco-queue-1 + length taco-queue-2) ]
end



to paint
  if mouse-down? = true[
    ask patch mouse-xcor mouse-ycor[set pcolor culler]
  ]
  wait 0.1
end

to paint-row
  if mouse-down? = true[
    ask patch mouse-xcor mouse-ycor[set pcolor culler]
    ask patch mouse-xcor (mouse-ycor - 2) [set pcolor culler]
    ask patch mouse-xcor (mouse-ycor - 4) [set pcolor culler]
    ask patch mouse-xcor (mouse-ycor - 6) [set pcolor culler]
    ask patch mouse-xcor (mouse-ycor - 8) [set pcolor culler]
  ]
  wait 0.1

end

to fill
  if mouse-down? = true[
    ask patch mouse-xcor mouse-ycor[
      ask neighbors with [pcolor = [pcolor] of myself][
        set pcolor culler
      ]
      set pcolor culler
    ]
  ]
  wait 0.1
end

to spawn
  if mouse-down? = true[
    ask patch mouse-xcor mouse-ycor[spawn-student]
  ]
  wait 0.1
end



;Observer context
;generates people at a specific probabilities dependent on the time
to generate-people
  let gen-prob 0.0
  ifelse ticks < 1800 [   ;we use our ticks as time, as each tick = 1 second
    set gen-prob 0.075 * (ticks / 1800)
  ] [
    ifelse ticks < 5400 [
      let prob-start 0.075
      set gen-prob prob-start + (0.2 * ((ticks - 1800) / 3600))
    ] [
      ifelse ticks < 8100 [
        set gen-prob 0.275
      ] [
        ifelse ticks < 10800 [
          let prob-start 0.275
          set gen-prob prob-start - (0.25 * ((ticks - 8100) / 2700))
        ] [
          let prob-start 0.025
          set gen-prob prob-start - (0.025 * ((ticks - 10800) / 1800))
        ]
      ]
    ]
  ]

  if random-float 1 < gen-prob [ ; we use one random after setting the gen-prob properly
    ask patch -8 37 [  ;;patch -8 37 is our entrance patch
      spawn-student  ;spawn-student gives us a random student
    ]
  ]
end

;patch context
;spawns a properly initialized student on the desired patch
to spawn-student
  sprout 1[
    set size 2
    set my-seat 0
    set mqueue (list [])
    set stations (list [])
    set sequence []
    set sequence-ticks 8

    set color blue
    set-restrictions-and-desires

    ifelse ticks < 3600 [
      ifelse random-float 1.0 < 0.05 [
        set athlete? true
        set color pink
      ][
        set athlete? false
      ]
    ][
      ifelse random-float 1.0 < 0.35 [   ;;35 % likelihood gathered from midd data
        set athlete? true
        set color pink
      ][
        set athlete? false
      ]
    ]

    set patience random 5 + 15
    ifelse (patience < line-length) [
      set mqueue (list "enter" "leave")
      set in-line? false
    ] [
      set-mqueue-and-stations
    ]

  ]

end


;Turtle Context
;initializes whether a turtle has dietary restrictions or not,
;then initializes its desires, to snack, eat dessert, a meal, work
;or get something to go.
to set-restrictions-and-desires

  ;we have a slider for how many people have a dietary restriction
  if random-float 1.0 < dietary-restriction-pct[
    set restricted? true

    ;;these are roughly realistic numbers, not including gluten free
    ;;of vegans being much more unlikely than vegetarians
    ifelse random-float 1.0 < 9.0 [
      set restrictions "vegetarian"
      set color green

    ]
    [
      set restrictions "vegan"
      set color green + 3
    ]
  ]
  ;the below line determines the likelihood of someone getting a snack or dessert,
  ;and it is scaled such that if the meal-quality is 0 (out of 10) we havea 22% chance of
  ;skipping a meal entirely and just getting a snack or dessert
  ifelse random-float 1.0 < (0.22 - ((meal-quality / 100) * 2)) [
    set desires one-of ["snack" "dessert"]

    ;we set an appropriate time to eat
    set tte 600
  ][
    ;;otherwise there is a 15% chance of getting something to go, because we are
    ;;busy midd students
    ifelse random-float 1.0 < 0.15 [
      set desires "to-go"
    ]
    [
      ;a 1% chance of working, because working in ross dining hall is weird and noisy
      ifelse random-float 1.0 < 0.01 [
        set desires "work"
        set tte 3600
      ]
      [
        ;;and everyone else just gets a meal
        set desires "meal"
        set tte random (max-meal-length * 60) ;;setting time-to-eat proportional to the desire,
      ]
    ]
  ]

end


;turtle context
;initializes the turtles movement queue and stations (which
;are the food stations it wants to visit) based on the initialized desires
to set-mqueue-and-stations
  let stationlist (list "station-1" "station-2" "pizza" "salad-bar") ;;the list of possible stations for a normal meal
  let v-stationlist (list "salad-bar" "station-2" "bagel" "vfridge" "vsnackfridge") ;;the list of stations for a vegan/vegetarian
  let snack-stationlist (list "bagel" "pizza" "panini" "cereal") ;the list of "snack" stations

  ifelse desires = "meal" [ ;;set our stations if they want a full meal
    set mqueue (list "food" "drink" "sit" "leave")
    ifelse restrictions != "vegan" and restrictions != "vegetarian" [ ;if they arent restricted
      ifelse athlete? [
        set stations n-of 3 stationlist ;;athletes eat more
      ][
        set stations n-of 2 stationlist
      ]
      if taco? and (random-float 1 < 0.9) [
        set stations remove-item 0 stations
        set stations fput "taco" stations
      ]
    ][
      ;;if they are restricted, we only go to the stations for dietary restrictions
      set stations n-of 2 v-stationlist
    ]
    ][ifelse desires = "work" [ ;;we only need to sit and leave if we came to work
      set mqueue (list "sit" "leave")
    ][
      ifelse desires = "snack"[ ;;snacking involves only going to snack stations
        set mqueue (list "food" "sit" "leave")
        set stations (list one-of snack-stationlist)

        ][ifelse desires = "to-go"[   ;to-go involves just getting food and leaving
          set mqueue (list "food" "leave")
          set stations n-of 2 (sentence stationlist snack-stationlist)
          ][if desires = "dessert"[  ;;dessert follows the same principle
            set mqueue (list "food" "sit" "leave")
            set stations (list "dessert")

          ]
        ]
      ]
    ]
  ]


  ;after we set up our movement queue, we have to remember to enter
  ;;and init in-line
  set mqueue fput "enter" mqueue
  set in-line? false


end

;LINE INIT FUNCTIONS
;OBSERVER CONTEXT

;the following line-init functions are identical in structure so only
;one will be commented
;for the respective lines they create, they initialize the patch values of
;properly colored patches to create a "line" of patches
;and then recolor those patches so lines are not visible

;initializes the salad line
to init-salad-line
  set salad-queue []   ;we set the global salad queue to zero
  ask patches with [pcolor = 56] [ ;;this is our chosen color for salad-line patches
    ifelse (pxcor = 32) and (pycor = -21) [
      ;;our start patch is hardcoded as the "back" of the line
      ;;and starts as both the back and the front of the line when the queue is empty
      set salad-line "back"
      set walk? true
    ] [
      ;;all other patches are not the back, there is only one back
      set salad-line "yes"
      set walk? true
    ]
    ;;afterwards we set the pcolor of these patches to white, so you cannot see them
    set pcolor 9.9
  ]
end

;initializes the station 1 line, identical to above
to init-station-1-line
  set station-1-queue []
  ask patches with [pcolor = 14] [
    ifelse (pxcor = 68) and (pycor = -15) [
      set station-1-line "back"
      set walk? true
    ] [
      set station-1-line "yes"
      set walk? true
    ]
    set pcolor 9.9
  ]
end

;initializes the station 2 line, identical to above
to init-station-2-line
  set station-2-queue []
  ask patches with [pcolor = 13] [
    ifelse (pxcor = 89) and (pycor = -2) [
      set station-2-line "back"
      set walk? true
    ] [
      set station-2-line "yes"
      set walk? true
    ]
    set pcolor 9.9
  ]
end

;initializzes the pizza line, identical to above
to init-pizza-line
  set pizza-queue []
  ask patches with [pcolor = 12] [
    ifelse (pxcor = 47) and (pycor = 7) [
      set pizza-line "back"
      set walk? true
    ] [
      set pizza-line "yes"
      set walk? true
    ]
    set pcolor 9.9
  ]
end


;initializes the taco line, identical to above
to init-taco-line
  set taco-queue-1 []
  set taco-queue-2 []
  ask patches with [pcolor = 34] [
    ifelse ((pxcor = 70) and (pycor = -8)) or ((pxcor = 70) and (pycor = -3)) [
      set taco-line "back"
      set walk? true
    ] [
      set taco-line "yes"
      set walk? true
    ]
    set pcolor 9.9
  ]
end



;;patch context
;;here we just label the patches based on the colors of the loaded in picture
to label-patches
  ask patches [
    ifelse pcolor = white or pcolor = 45[ set walk? true ][set walk? false]   ; set walkable patches
    if pcolor = 9 [ set seating? true ]                                  ; set seating
    if pycor = 18 and (-45 < pxcor and pxcor <= -43)[                    ; set food types based on patch color
      set food-type "dessert"
    ]
    if pxcor = 94 and (-3 > pycor and pycor > -7)[
      set food-type "bagel"
    ]
    if pxcor = -66 and (1 < pycor and pycor < 7)[
      set food-type "panini"
    ]
    if pxcor = -15 and (26 < pycor and pycor < 35)[
      set food-type "cereal"
    ]
    if pxcor = -15 and (22 < pycor and pycor < 25)[
      set food-type "vfridge"
    ]
    if pxcor = -37 and (20 < pycor and pycor < 23)[
      set food-type "vsnackfridge"
    ]
    if pcolor = 95.1 [
      if ([pcolor] of (patch pxcor (pycor - 1))) != 95.1 [             ; set drinks
        ask patch pxcor (pycor - 1) [
          set food-type "drink"
        ]
      ]
    ]
    if count neighbors4 with [pcolor = 9 and pxcor = [pxcor] of myself] = 2 [
      set walk? false
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
203
15
2221
1034
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-100
100
-50
50
0
0
1
ticks
30.0

BUTTON
24
25
88
59
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
42
617
106
651
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
2079
24
2216
69
NIL
time
17
1
11

SLIDER
24
433
199
466
dietary-restriction-pct
dietary-restriction-pct
0
1.0
0.09
0.01
1
NIL
HORIZONTAL

CHOOSER
22
823
161
868
culler
culler
9.9 9 0 15 55 56 105 14 13 12 5 125 45 35 34
14

BUTTON
20
868
84
902
NIL
paint\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
23
910
87
944
NIL
fill
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1634
418
1822
442
pizza\n
16
0.0
1

TEXTBOX
1944
649
2132
673
food station 1\n
16
0.0
1

TEXTBOX
1972
484
2160
508
food station 2\n
16
0.0
1

TEXTBOX
2170
549
2193
611
BAGELS\n\n
16
0.0
1

BUTTON
97
913
165
947
NIL
spawn
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1267
305
1315
324
drinks\n
16
0.0
1

TEXTBOX
1427
302
1481
326
drinks
16
0.0
1

TEXTBOX
1575
657
1650
685
salad bar
16
0.0
1

TEXTBOX
529
455
548
625
P A N I N I
16
0.0
1

TEXTBOX
1075
157
1093
269
C E R E A L
13
0.0
1

TEXTBOX
817
299
835
327
V GF
11
0.0
1

TEXTBOX
1074
284
1097
312
V\nGF
11
0.0
1

TEXTBOX
740
317
798
336
Dessert
15
0.0
1

TEXTBOX
680
315
729
335
drinks
16
0.0
1

BUTTON
93
873
178
907
NIL
paint-row
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1939
198
2029
243
# of Students
count turtles
17
1
11

TEXTBOX
893
359
1136
399
S e a t i n g   b l o c k     A
17
0.0
1

TEXTBOX
889
149
1077
174
Seating Block B
17
0.0
1

TEXTBOX
1263
557
1451
582
Seating Block C
17
0.0
1

BUTTON
109
617
173
651
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
40
785
175
825
Dev Tools
16
0.0
1

SWITCH
88
382
192
415
Swipes?
Swipes?
0
1
-1000

SLIDER
28
484
201
517
meal-quality
meal-quality
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
23
530
205
563
max-meal-length
max-meal-length
15
90
27.0
1
1
minutes
HORIZONTAL

PLOT
1870
33
2070
183
Students Over Time
Time
students
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
1654
35
1854
185
Seating Over Time
Time
Open Seats
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [seating? = true and not any? turtles-here]"

PLOT
1430
35
1630
185
Avg Line-Length Over Time
Time
Avg. Line Length
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot line-length"

MONITOR
1715
199
1794
244
Open Seats
count patches with [seating? = true and not any? turtles-here]
17
1
11

MONITOR
1492
195
1599
240
Avg. Line Length
line-length
17
1
11

SWITCH
89
348
194
381
taco?
taco?
0
1
-1000

@#$#@#$#@
## Middlebury Ross Dining Hall Simulation
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="max-meal-length">
      <value value="15"/>
      <value value="30"/>
      <value value="45"/>
      <value value="60"/>
      <value value="75"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Swipes?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dietary-restriction-pct">
      <value value="0.1"/>
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.7"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-quality">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
