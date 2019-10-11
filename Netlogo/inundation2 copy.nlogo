extensions [csv gis]

globals[
  GEODATASET
  FLOOD_HEIGHT
  MHHW
  MSL
  TIME
  TOTAL
  PROB_LIST
  SUBSIDY_PV
  CLASS
]

turtles-own[
  Latitude
  Longtitude
  Elevation
  Stories
  Basement
  TotalMarketValue
  StructureValue
  Sq.ft.
  Inundation
  Cost_to_personal_property
  Future_loss
  Future_benefit
  Damage_pct
  Moved?
]

;; set different breed
;; poor / normal income people have different discount rate
breed [ poors poor ]
breed [ normals normal ]

to setup
  clear-all

  Initialize_list ;; initilize lists
  Input_flood_data ;; input data from data.csv
  Update_coefficient_TOTAL  ;; update values and coefficient in each tick
  Update_coefficient_SUBSIDY_PV
  set FLOOD_HEIGHT Flood_Height_Meters
  set MHHW MHHW_Meters
  set MSL MSL_Meters
  set TIME 0
  set GEODATASET gis:load-dataset "data/test.shp"
  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of GEODATASET))
  House_property
  reset-ticks
end

to Go
  ;; stop condition is that every agent has moved
  if ( not any? turtles with [ not moved? ] ) or TIME > 100 [
    stop
  ]

  Update_coefficient_TOTAL  ;; update values and coefficient in each tick
  Update_coefficient_SUBSIDY_PV ;; update subsidy pv value

  ask turtles [
    Update_values   ;; update values for every agent
    Change_color ;; change color if agents have moved in this year
  ]
  set TIME TIME + 1 ;; add time
  tick
end

to House_property
  foreach gis:feature-list-of GEODATASET [ vector-feature ->
    show vector-feature
    let loc gis:location-of(first(first (gis:vertex-lists-of vector-feature)))
    if not empty? loc[
      create-turtles 1[
      set xcor item 0 loc
      set ycor item 1 loc
      set size 10
      set shape "house"
      set TotalMarketValue gis:property-value vector-feature "MARKETVALU"
      set StructureValue 100
      set moved? False

      ]
    ]
  ]
end

to Inundation_damage_cost
  if Inundation <= 2
  [ set Cost_to_personal_property 3172]
  if Inundation > 2 and Inundation <= 3
  [ set Cost_to_personal_property 4917]
  if Inundation > 3 and Inundation <= 4
  [ set Cost_to_personal_property 7207]
  if Inundation > 4 and Inundation <= 5
  [ set Cost_to_personal_property 13914]
  if Inundation > 5 and Inundation <= 6
  [ set Cost_to_personal_property 14777]
  if Inundation > 6 and Inundation <= 7
  [ set Cost_to_personal_property 17700]
  if Inundation > 7 and Inundation <= 8
  [ set Cost_to_personal_property 20624]
  if Inundation > 8 and Inundation <= 9
  [ set Cost_to_personal_property 23547]
  if Inundation > 9 and Inundation <= 10
  [ set Cost_to_personal_property 26470]
  if Inundation > 10 and Inundation <= 11
  [ set Cost_to_personal_property 29394]
  if Inundation > 11 and Inundation <= 12
  [ set Cost_to_personal_property 32317]
  if Inundation > 12 and Inundation <= 24
  [ set Cost_to_personal_property 43001]
  if Inundation > 24 and Inundation <= 36
  [ set Cost_to_personal_property 46633]
  if Inundation > 36
  [ set Cost_to_personal_property 50000]

end

to Setting_agents
  ifelse TotalMarketValue >= 3000 [
    set breed normals
    set shape "triangle"
    set color blue
  ]
  [ set breed poors
    set shape "circle"
    set color blue
  ]
  set moved? false
  damage_percentage ;; set random valse for damage percentage
                                  ;; set expected loss for the future standing at year one and update at every tick
                                  ;; future loss is set as total coefficient * property value * damage percentage
  if breed = normals
  [
    set future_loss ( item 0 TOTAL) * 0.9 * damage_pct
  ]
  if breed = poors
  [
    set future_loss ( item 1 TOTAL) * 0.9 * damage_pct
  ]
end

to Damage_percentage
  if Inundation <= 0
  [set damage_pct 0.255]
  if Inundation > 0 and Inundation <= 1
  [set damage_pct 0.32]
  if Inundation > 1 and Inundation <= 2
  [set damage_pct 0.387]
  if Inundation > 2 and Inundation <= 3
  [set damage_pct 0.455]
  if Inundation > 3 and Inundation <= 4
  [set damage_pct 0.522]
  if Inundation > 4 and Inundation <= 5
  [set damage_pct 0.586]
  if Inundation > 5 and Inundation <= 6
  [set damage_pct 0.645]
  if Inundation > 6 and Inundation <= 7
  [set damage_pct 0.698]
  if Inundation > 7 and Inundation <= 8
  [set damage_pct 0.742]
  if Inundation > 8 and Inundation <= 9
  [set damage_pct 0.777]
  if Inundation > 9 and Inundation <= 10
  [set damage_pct 0.801]
  if Inundation > 10
  [set damage_pct 0.811]
end

to Update_coefficient_TOTAL
  ;; coefficient of expected future loss
  ;; if hyperbolic? is true then using hyperbolic discount mode with hyperbolic rate alpha
  ifelse Hyperbolic? = false [
    ;; set TOTAL 0
    let iter 0
    loop [
      if iter >= (Period - TIME) [ stop ] ;; stop condition is range out of period
                                          ;; set different cumulative future loss
      set TOTAL replace-item 0 TOTAL ( ( item 0 TOTAL) + ( 1 / (( 1 + normal_dis ) ^ iter ) * ( item ( iter + TIME ) PROB_LIST ) ))
      set TOTAL replace-item 1 TOTAL ( ( item 0 TOTAL) + ( 1 / (( 1 + poor_dis ) ^ iter ) * ( item ( iter + TIME ) PROB_LIST ) ))
      set iter iter + 1
      ;;show TOTAL  ;; show to check calculation
    ]
  ]
  [
    let iter 0
    loop [
      if iter >= (Period - TIME) [ stop ] ;; stop condition is range out of period
                                          ;; set different cumulative future loss
      set TOTAL replace-item 0 TOTAL ( ( item 0 TOTAL) + ( 1 / (( 1 + normal_dis + Hyperbolic_rate * iter ) ^ iter ) * ( item ( iter + TIME ) PROB_LIST ) ))
      set TOTAL replace-item 1 TOTAL ( ( item 0 TOTAL) + ( 1 / (( 1 + poor_dis + Hyperbolic_rate * iter  ) ^ iter ) * ( item ( iter + TIME ) PROB_LIST ) ))
      set iter iter + 1
      ;;show TOTAL  ;; show to check calculation
    ]
  ]
end

;; function to update one-time subsidy
to Update_coefficient_SUBSIDY_PV

  ;; update subsidy's pv according to time
  set SUBSIDY_PV replace-item 0 SUBSIDY_PV ( Subsidy / ( 1 + normal_dis ) ^ TIME )
  set SUBSIDY_PV replace-item 1 SUBSIDY_PV ( Subsidy / ( 1 + poor_dis ) ^ TIME )

  ;;show SUBSIDY_PV

end

;; function to update values for agent
to Update_values

  if breed = normals
  [
    set future_loss ( item 0 TOTAL) * 0.9 * damage_pct
    if Government_strategy = "Fixed-Benefit" [
      let iter 0
      loop [
        if iter >= (Period - TIME) [ stop ] ;; stop condition is range out of period
                                            ;; set different cumulative future benefit
        set future_benefit future_benefit +  ( Fix_benefit / (( 1 + normal_dis) ^ iter ) )
        set iter iter + 1
      ]
    ]
  ]
  if breed = poors
  [
    set future_loss ( item 1 TOTAL) * 0.9 * 0.5 ;;damage_pct
    if Government_strategy = "Fixed-Benefit" [
      let iter 0
      loop [
        if iter >= (Period - TIME) [ stop ] ;; stop condition is range out of period
                                            ;; set different cumulative future benefit
        set future_benefit future_benefit +  ( Fix_benefit / (( 1 + Poor_dis) ^ iter ) )
        set iter iter + 1
      ]
    ]
  ]

  ;;show future_loss

end
to Change_color

  ;; if moving cost plus pv of subsidy is greater than future loss then residents will move
  if breed = normals
  [
    ifelse Government_strategy = "One-time-Subsidy" [
      if TotalMarketValue - ( item 0 SUBSIDY_PV)- future_loss <= threshold [
        set color red  ;; change color to red if moved
        set moved? True ;; resident has moved
      ]
    ]
    [
      if TotalMarketValue - future_benefit - future_loss <= threshold [
        set color red  ;; change color to red if moved
        set moved? True ;; resident has moved
      ]
    ]
  ]
  if breed = poors
  [
    ifelse Government_strategy = "One-time-Subsidy" [
      if TotalMarketValue - ( item 1 SUBSIDY_PV)- future_loss <= threshold [
        set color red  ;; change color to red if moved
        set moved? True ;; resident has moved
      ]
    ]
    [
      if TotalMarketValue - future_benefit - future_loss <= threshold [
        set color red  ;; change color to red if moved
        set moved? True ;; resident has moved
      ]
    ]
  ]

end

;; function to plug in flood probability data
to Input_flood_data
  ;; initilize PROB_LIST and read probability data from outside source
  set PROB_LIST [ ]

  file-close
  if Flood_type = "100_year_NY" [
    file-open "data/100_NY_4.5.csv"
  ]
  let iter 0
  loop [
    ifelse file-at-end? [
      ;; show iter
      ;; show PROB_LIST
      stop ]
    [
      set PROB_LIST lput file-read PROB_LIST
      set iter iter + 1
    ]
  ]
  file-close
end

;; function to initialize lists
to Initialize_list
  set SUBSIDY_PV [] ;; initialize SUBSIDY_PV list
  set TOTAL [] ;; initialize TOTAL list
  let iter 0
  set CLASS 2
  loop [
    if iter > CLASS [ stop ]
    set SUBSIDY_PV lput 0 SUBSIDY_PV
    set TOTAL lput 0 TOTAL
    set iter iter + 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
535
20
1144
630
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-600
0
0
600
0
0
1
ticks
30.0

BUTTON
9
14
75
47
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
5
82
124
142
Flood_Height_Meters
10.0
1
0
Number

INPUTBOX
4
150
125
210
MHHW_Meters
0.0
1
0
Number

INPUTBOX
4
219
126
279
MSL_Meters
0.0
1
0
Number

CHOOSER
140
83
278
128
Location
Location
"NY"
0

CHOOSER
140
139
303
184
Government_Strategy
Government_Strategy
"One-time-Subsidy" "Fixed-Benefits"
0

SLIDER
138
194
310
227
Period
Period
0
200
87.0
1
1
NIL
HORIZONTAL

SLIDER
139
238
311
271
Fix_benefit
Fix_benefit
0
10000
0.0
1
1
NIL
HORIZONTAL

SLIDER
140
280
312
313
Normal_dis
Normal_dis
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
185
330
357
363
Poor_dis
Poor_dis
0
1
0.0
0.01
1
NIL
HORIZONTAL

SWITCH
4
285
133
318
Hyperbolic?
Hyperbolic?
1
1
-1000

SLIDER
2
330
174
363
Hyperbolic_rate
Hyperbolic_rate
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
4
375
176
408
Subsidy
Subsidy
0
10000
400.0
100
1
NIL
HORIZONTAL

SLIDER
4
422
176
455
Threshold
Threshold
-1000
10000
51.0
1
1
NIL
HORIZONTAL

BUTTON
91
14
154
47
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
316
36
454
81
Flood_type
Flood_type
"100_year_NY"
0

PLOT
8
471
202
621
Number of moved
Time
Number
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [moved?]"

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
NetLogo 6.1.1
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