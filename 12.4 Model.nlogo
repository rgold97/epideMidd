; EpideMidd

; to do:
; 2 different numbers of students initially infected, 2 different infection rates
; how long does illness die out take
; how many students get exposed in each building (dining hall competition, freshman dorm competition, senior hang-outs competition)

extensions [csv]

__includes["12.4 World Setup.nls"] ; contains setup-patches and assign-rooms

globals [
  num_students
  day
  building

  sun_data
  mon_data
  tues_data
  wed_data
  thurs_data
  fri_data
  sat_data

  num_exp
  num_exp_proc
  num_exp_ross
  num_exp_atd
  num_exp_gym
  num_exp_lib
  num_exp_bat
  num_exp_allen
  num_exp_had
  num_exp_stew
  num_exp_th
  num_exp_ridgeline
  num_exp_bihall
]

turtles-own [
  ; turtle variables are target location, room location, and health status markers
  room
  healthy?
  exposed?
  sick?
  symptomatic?
  recovered?
  unassigned?

  ticks-left-exposed
  ticks-left-sick

  previous_task
  task
  destination
  free_time_prob

  ; lists that store the turtle's hour-by-hour sequence to execute each day
  sun_seq
  mon_seq
  tues_seq
  wed_seq
  thurs_seq
  fri_seq
  sat_seq

  ; stores which sequence the turtles should be following, based on day global variable
  current_seq
]

patches-own [
  ; for now, keeping track of types of buildings and also name
  ; these variables might get changed around in the future
  academic?
  dining?
  common?
  dorm?
  name
]

; global context
to set-up
  ; clear past
  clear-all
  reset-ticks

  set sun_data csv:from-file "sun_schedules.csv"
  set mon_data csv:from-file "mon_schedules.csv"
  set tues_data csv:from-file "tues_schedules.csv"
  set wed_data csv:from-file "wed_schedules.csv"
  set thurs_data csv:from-file "thurs_schedules.csv"
  set fri_data csv:from-file "fri_schedules.csv"
  set sat_data csv:from-file "sat_schedules.csv"

  set num_students 2390

  set num_exp num_initially_infected

  ; make world and put students in it
  import-pcolors "Middlebury Map.jpg"
  label-patches
  setup-turtles
end


; global context
to setup-turtles
  ; create student population
  create-turtles num_students [

    ; set asthetics
    set shape "circle"
    set size 1.5
    set color green

    ; set health status
    set sick? FALSE
    set healthy? TRUE
    set exposed? FALSE
    set recovered? FALSE
    set symptomatic? TRUE   ; only affects behavior when sick? = TRUE

    set ticks-left-exposed 0
    set ticks-left-sick 0

    set unassigned? TRUE
  ]

  assign-rooms
  assign-schedules

  ; make some turtles sick to start with
  ask n-of num_initially_infected turtles [
    set color red
    set sick? TRUE
    set healthy? FALSE
    if room = "Battell" [
      set num_exp_bat (num_exp_bat + 1)
    ]
    if room = "Allen" [
      set num_exp_allen (num_exp_allen + 1)
    ]
    if room = "Hadley" [
      set num_exp_had (num_exp_had + 1)
    ]
    if room = "Stewart" [
      set num_exp_stew (num_exp_stew + 1)
    ]
    if room = "RidgelineSuites" [
      set num_exp_ridgeline (num_exp_ridgeline + 1)
    ]
    if room = "RidgelineTownhouses"[
      set num_exp_th (num_exp_th + 1)
    ]
  ]
  ask n-of round(num_initially_infected * percent_asymptomatic / 100) turtles [
    set symptomatic? FALSE
  ]
end


; global context
to go
  ; if it is a new day
  if (ticks mod 24) = 0 [
    update-day ; change whether it's sun, mon, tues, etc.
  ]

  ; each timestep, turtles should move, infect each other, and recover from illness
  move-turtles
  infect
  go-through-exposure
  go-through-sickness
  if ticks = 672 [stop]
  tick
end


; global context
to update-day
  ; mod 1 week
  if (ticks mod 168) = 0 [
    set day "sun"
    ask turtles [
      set current_seq sun_seq
    ]
  ]
  if (ticks mod 168) = 24 [
    set day "mon"
    ask turtles [
      set current_seq mon_seq
    ]
  ]
  if (ticks mod 168) = 48 [
    set day "tues"
    ask turtles [
      set current_seq tues_seq
    ]
  ]
  if (ticks mod 168)= 72 [
    set day "wed"
    ask turtles [
      set current_seq wed_seq
    ]
  ]
  if (ticks mod 168)  = 96 [
    set day "thurs"
    ask turtles [
      set current_seq thurs_seq
    ]
  ]
  if (ticks mod 168) = 120 [
    set day "fri"
    ask turtles [
      set current_seq fri_seq
    ]
  ]
  if (ticks mod 168) = 144 [
    set day "sat"
    ask turtles [
      set current_seq sat_seq
    ]
  ]
end


; global context
to infect
  ; if a turtle is healthy
  ask turtles with [healthy? = TRUE] [
    ; if there are any sick turtles in its radius
    ; they have certain probability of getting infected
    if any? turtles in-radius 0.5 with [sick? = TRUE] and random 100 < infection_rate [

      if name = "ProctorDining" [
        set num_exp_proc (num_exp_proc + 1)
      ]
      if name = "RCD" [
        set num_exp_ross (num_exp_ross + 1)
      ]
      if name = "ATD" [
        set num_exp_atd (num_exp_atd + 1)
      ]
      if name = "MFH" [
        set num_exp_gym (num_exp_gym + 1)
      ]
      if name = "LIB" [
        set num_exp_lib (num_exp_lib + 1)
      ]
      if name = "Allen" [
        set num_exp_allen (num_exp_allen + 1)
      ]
      if name = "Battell" [
        set num_exp_bat (num_exp_bat + 1)
      ]
      if name = "Hadley" [
        set num_exp_had (num_exp_had + 1)
      ]
      if name = "Stewart" [
        set num_exp_stew (num_exp_stew + 1)
      ]
      if name = "RidgelineSuites" [
        set num_exp_ridgeline (num_exp_ridgeline + 1)
      ]
      if name = "RidgelineTownhouses" [
        set num_exp_th (num_exp_th + 1)
      ]
      if name = "MBH" [
        set num_exp_bihall (num_exp_bihall + 1)
      ]

      set exposed? TRUE
      set num_exp (num_exp + 1)
      ; set ticks-left-exposed to about 2 days, STD = 12 hours
      set ticks-left-exposed round (random-normal 48 12)
      set healthy? FALSE
      set color orange
    ]
  ]
end

to go-through-exposure
  ask turtles with [exposed? = TRUE] [
    set ticks-left-exposed (ticks-left-exposed - 1)
    if ticks-left-exposed = 0 [
      set exposed? FALSE
      set sick? TRUE
      set color red
      ; set ticks-left-sick to about 4 days, STD = 1 day
      set ticks-left-sick round (random-normal 96 24)
    ]
  ]
end

to go-through-sickness
  ask turtles with [sick? = TRUE] [
    set ticks-left-sick (ticks-left-sick - 1)
    if ticks-left-sick = 0 [
      set sick? FALSE
      set recovered? TRUE
      set color blue
    ]
  ]
end


; global context
to move-turtles
  ; this version makes it look cool because turtles move around inside buildings!
  ; (if they stay in places longer than 1 tick.  we should use this if that is common!
  ; they stay put in their rooms, though, so they don't move around when they sleep :)
  ask turtles [
    ; symptomatic students go to a certain percentage of their obligations
    ifelse ((sick? = TRUE) and (symptomatic? = TRUE) and (random 100 < home_sick)) [
      move-to room
    ][
      set task (item (ticks mod 24) current_seq)
      execute-task
      ]
    ]

  ; this version probably improves runtime, because turtles only move if their task changes
  ;ask turtles [
  ;  set previous_task task
  ;  set task (item (ticks mod 24) current_seq)
  ;  if task != previous_task [
  ;     execute-task
  ;  ]
end


; turtle context
to execute-task
  ifelse task = "h" [
    move-to room
  ][
    ifelse task = "f" [
      go-free
    ][
      ; otherwise, the task is a building name where the turtle needs to go to class
      set building task
      set destination one-of patches with [name = building]
      move-to destination
    ]
  ]
end

; turtle context
to go-free
  ; if it's before 10 pm, follow this free time schedule
  ifelse (ticks mod 24) < 22 [
    set free_time_prob random-float 1
    ; 30% go to their rooms
    if free_time_prob <= 0.3 [
      set destination room
    ]
    ; 5% go to the gym (this makes about 1,000 people go to the gym a day)
    if (0.3 < free_time_prob and free_time_prob <= 0.35) [
      set destination one-of patches with [name = "MFH"]
    ]
    ; 5% go to McCullough
    if (0.35 < free_time_prob and free_time_prob <= 0.4) [
      set destination one-of patches with [name = "McCullough"]
    ]
    ; 20% go to Bi Hall
    if (0.4 < free_time_prob and free_time_prob <= 0.6) [
      set destination one-of patches with [name = "MBH"]
    ]
    ; 10% go to Axinn
    if (0.6 < free_time_prob and free_time_prob <= 0.7) [
      set destination one-of patches with [name = "AXN"]
    ]
    ; 5% go to a random academic building
    if (0.7 < free_time_prob and free_time_prob <= 0.75) [
      set destination one-of patches with [academic? = TRUE]
    ]
    ; 5% go to a random dorm
    if (0.75 < free_time_prob and free_time_prob <= 0.8) [
      set destination one-of patches with [dorm? = TRUE]
    ]
    ; 20% go to the library
    if (0.8 < free_time_prob and free_time_prob <= 1) [
      set destination one-of patches with [name = "LIB"]
    ]
  ][
    ; if it's 10 or 11 pm
    ifelse ((day = "fri") or (day = "sat")) [
      ; partayyyyyy
      set free_time_prob random-float 1
      ; 50% go to their room
      if (free_time_prob <= 0.5) [
        set destination room
      ]
      ; 45% go to a random dorm
      if (0.5 < free_time_prob and free_time_prob <= 0.95) [
        set destination one-of patches with [dorm? = TRUE]
      ]
      ; 5% go to the library
      if (0.95 < free_time_prob and free_time_prob <= 1) [
        set destination one-of patches with [name = "LIB"]
      ]
    ][
      ; if it's a school night
      set free_time_prob random-float 1
      ; 65% go to their room
      if (free_time_prob <= 0.65) [
        set destination room
      ]
      ; 10% go to Bi Hall
      if (0.65 < free_time_prob and free_time_prob <= 0.75) [
        set destination one-of patches with [name = "MBH"]
      ]
      ; 5% go to Axinn
      if (0.75 < free_time_prob and free_time_prob <= 0.8) [
        set destination one-of patches with [name = "AXN"]
      ]
      ; 5% go to a random academic building
      if (0.8 < free_time_prob and free_time_prob <= 0.85) [
        set destination one-of patches with [academic? = TRUE]
      ]
      ; 15% go to the library
      if (0.85 < free_time_prob and free_time_prob <= 1) [
        set destination one-of patches with [name = "LIB"]
      ]
    ]
  ]

  move-to destination
end

; global context
to assign-schedules
  foreach (range 2390) [x -> ask turtle x [set sun_seq (item (x + 1) sun_data)]]
  foreach (range 2390) [x -> ask turtle x [set mon_seq (item (x + 1) mon_data)]]
  foreach (range 2390) [x -> ask turtle x [set tues_seq (item (x + 1) tues_data)]]
  foreach (range 2390) [x -> ask turtle x [set wed_seq (item (x + 1) wed_data)]]
  foreach (range 2390) [x -> ask turtle x [set thurs_seq (item (x + 1) thurs_data)]]
  foreach (range 2390) [x -> ask turtle x [set fri_seq (item (x + 1) fri_data)]]
  foreach (range 2390) [x -> ask turtle x [set sat_seq (item (x + 1) sat_data)]]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
763
470
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-272
272
-225
225
0
0
1
ticks
30.0

BUTTON
74
192
141
225
NIL
set-up
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
74
343
137
376
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

SLIDER
10
257
202
290
infection_rate
infection_rate
0
50
10.0
5
1
percent
HORIZONTAL

PLOT
774
10
1142
212
Disease status
Time
Num Students
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Healthy" 1.0 0 -14439633 true "" "plot count turtles with [healthy? = TRUE]"
"Exposed" 1.0 0 -955883 true "" "plot count turtles with [exposed? = TRUE]"
"Sick" 1.0 0 -2674135 true "" "plot count turtles with [sick? = TRUE]"
"Recovered" 1.0 0 -13791810 true "" "plot count turtles with [recovered? = TRUE]"
"Total Students" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
10
107
200
140
num_initially_infected
num_initially_infected
0
200
50.0
10
1
NIL
HORIZONTAL

MONITOR
776
314
826
359
Proctor
num_exp_proc
17
1
11

MONITOR
832
314
882
359
Ross
num_exp_ross
17
1
11

MONITOR
888
314
938
359
Atwater
num_exp_atd
17
1
11

MONITOR
640
16
697
85
Day
day
17
1
17

MONITOR
701
16
758
85
Time
ticks mod 24
17
1
17

MONITOR
576
16
636
85
Week
floor (ticks / 168) + 1
17
1
17

TEXTBOX
777
247
986
285
Number of Students Exposed in Certain Buildings So Far:
14
0.0
1

MONITOR
776
399
826
444
Gym
num_exp_gym
17
1
11

MONITOR
831
399
881
444
Library
num_exp_lib
17
1
11

MONITOR
940
399
1011
444
Townhouses
num_exp_th
17
1
11

MONITOR
1015
399
1101
444
Ridgeline Suites
num_exp_ridgeline
17
1
11

MONITOR
885
399
935
444
Bi Hall
num_exp_bihall
17
1
11

MONITOR
975
314
1025
359
Battell
num_exp_bat
17
1
11

MONITOR
1030
314
1080
359
Allen
num_exp_allen
17
1
11

MONITOR
1085
315
1135
360
Hadley
num_exp_had
17
1
11

MONITOR
1142
315
1192
360
Stew
num_exp_stew
17
1
11

TEXTBOX
778
293
928
311
Dining Hall Duel
12
0.0
1

TEXTBOX
976
292
1126
310
Freshman Dorm War
12
0.0
1

TEXTBOX
777
378
927
396
Senior Spaces Battle
12
0.0
1

SLIDER
10
148
200
181
percent_asymptomatic
percent_asymptomatic
0
100
0.0
10
1
percent
HORIZONTAL

TEXTBOX
45
18
195
49
EpideMidd
25
0.0
1

TEXTBOX
32
54
182
86
Set these parameters and watch disease spread!
13
0.0
1

TEXTBOX
778
458
1008
491
Anna Hughes Hoge and Rose Gold, Fall 2018
11
0.0
1

SLIDER
9
297
204
330
home_sick
home_sick
0
100
0.0
10
1
percent of the time
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
