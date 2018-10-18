; Building up epideMidd in stages
; See Trello for next steps

; add button "set-up"
; add button "go"

;extensions [time]

breed [students student]
students-own [target]

to set-up
  clear-all

  setup-patches
  setup-students

  reset-ticks
end

to setup-patches
  ; using pink patches to represent buildings for now
  ask n-of 20 patches [
    set pcolor pink
  ]
end

to setup-students
  create-students 300 [
    setxy random-xcor random-ycor
    set shape "circle"
    set target one-of patches with [pcolor = pink]
    face target
    set color green
  ]
  ask one-of students [
    set color red
  ]
end

to go
  move-students
  tick
end

to move-students
  ask students [
    ; if already at the target, pick a new one
    if distance target = 0 [
      set target one-of patches with [pcolor = pink]
      face target
    ]
    ; if on top of the target, actually move onto it, or else keep moving toward it
    ; syntax here is that if the statement is true, do the 1st line.  if not, do the 2nd
    ifelse distance target < 1
    [move-to target]
    [forward 1]
  ]

end
