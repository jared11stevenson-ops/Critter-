# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/forms/stage1_head/forms.glb`  forward +z  render height 2.399 m (top 2.399); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.875 | 0.870 | -0.004 | 1.02 | 0.079 | +0.001 |
| back | 0.884 | 0.884 | +0.001 | 1.00 | 0.042 | +0.003 |
| front (3/4 ref, qualitative) | 0.577 | 0.424 | +0.149 | 0.83 | 0.269 | -0.092 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.199 | +0.006 | +3 |  |
| horns.solid_width | 0.119 | 0.116 | -0.003 | -3 |  |
| horns.extent | 0.381 | 0.388 | +0.007 | +2 |  |
| head.outer_width | 0.226 | 0.233 | +0.007 | +3 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.233 | +0.033 | +17 |  |
| head.solid_width | 0.213 | 0.233 | +0.020 | +10 |  |
| head.extent | 0.307 | 0.302 | -0.006 | -2 |  |
| snout.outer_width | 0.236 | 0.248 | +0.012 | +5 |  |
| snout.solid_width | 0.218 | 0.248 | +0.030 | +14 |  |
| snout.extent | 0.307 | 0.302 | -0.006 | -2 |  |
| neck.outer_width | 0.150 | 0.151 | +0.001 | +1 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.150 | +0.002 | +2 | y |
| neck.solid_width | 0.149 | 0.151 | +0.001 | +1 |  |
| neck.extent | 0.314 | 0.288 | -0.026 | -8 |  |
| neck_top.outer_width | 0.108 | 0.111 | +0.002 | +2 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.111 | +0.002 | +2 | y |
| neck_top.solid_width | 0.108 | 0.111 | +0.002 | +2 |  |
| neck_top.extent | 0.110 | 0.118 | +0.008 | +7 |  |
| neck_mid.outer_width | 0.115 | 0.119 | +0.004 | +4 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.119 | +0.004 | +4 | y |
| neck_mid.solid_width | 0.115 | 0.119 | +0.004 | +4 |  |
| neck_mid.extent | 0.124 | 0.136 | +0.012 | +10 |  |
| neck_base.outer_width | 0.252 | 0.246 | -0.005 | -2 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.242 | -0.003 | -1 | y |
| neck_base.solid_width | 0.250 | 0.244 | -0.005 | -2 |  |
| neck_base.extent | 0.314 | 0.288 | -0.026 | -8 |  |
| shoulders.outer_width | 0.402 | 0.417 | +0.015 | +4 | y |
| shoulders.solid_width | 0.402 | 0.417 | +0.015 | +4 |  |
| shoulders.extent | 0.436 | 0.443 | +0.006 | +1 |  |
| torso.outer_width | 0.423 | 0.415 | -0.008 | -2 |  |
| torso.solid_width | 0.413 | 0.415 | +0.003 | +1 |  |
| torso.extent | 0.537 | 0.476 | -0.060 | -11 |  |
| waist.outer_width | 0.460 | 0.447 | -0.013 | -3 | y |
| waist.solid_width | 0.460 | 0.447 | -0.013 | -3 |  |
| waist.extent | 0.468 | 0.454 | -0.014 | -3 |  |
| pelvis.outer_width | 0.419 | 0.409 | -0.011 | -3 |  |
| pelvis.solid_width | 0.405 | 0.409 | +0.004 | +1 |  |
| pelvis.extent | 0.446 | 0.440 | -0.006 | -1 |  |
| arm.outer_width | 0.399 | 0.393 | -0.006 | -2 |  |
| arm.solid_width | 0.387 | 0.392 | +0.005 | +1 |  |
| arm.extent | 0.537 | 0.476 | -0.060 | -11 |  |
| hand.outer_width | 0.302 | 0.300 | -0.002 | -1 |  |
| hand.solid_width | 0.294 | 0.299 | +0.005 | +2 |  |
| hand.extent | 0.463 | 0.459 | -0.004 | -1 |  |
| thigh.outer_width | 0.192 | 0.198 | +0.006 | +3 |  |
| thigh.solid_width | 0.187 | 0.196 | +0.009 | +5 |  |
| thigh.extent | 0.360 | 0.371 | +0.012 | +3 |  |
| shin.outer_width | 0.117 | 0.123 | +0.005 | +5 | y |
| shin.solid_width | 0.117 | 0.123 | +0.005 | +5 |  |
| shin.extent | 0.198 | 0.207 | +0.009 | +4 |  |
| foot.outer_width | 0.235 | 0.250 | +0.015 | +6 | y |
| foot.solid_width | 0.229 | 0.250 | +0.021 | +9 |  |
| foot.extent | 0.416 | 0.410 | -0.006 | -1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.126 | -0.005 | -4 | y |
| head.length (nape..snout tip) | 0.307 | 0.302 | -0.006 | -2 | y |
| foot.length (heel..toe) | 0.416 | 0.410 | -0.006 | -1 | y |
| torso.chest_to_back_depth | 0.513 | 0.460 | -0.053 | -10 | y |
| head.snout_tip_height | 2.008 | 2.011 | +0.003 | +0 |  |
| total_height (highest point) | 2.400 | 2.399 | -0.001 | -0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.367 | -0.033 | -1 | y |
| horn_A(rear/thick).span | 0.217 | 0.217 | +0.000 | +0 | y |
| horn_B(front/long).tip_height | 2.391 | 2.399 | +0.008 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.202 | +0.020 | +11 | y |
| horns.total_depth_spread (side) | 0.334 | 0.357 | +0.022 | +7 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.193 | +0.002 | +1 |  |
| horns.solid_width | 0.119 | 0.111 | -0.008 | -7 |  |
| horns.extent | 0.439 | 0.405 | -0.034 | -8 |  |
| head.outer_width | 0.210 | 0.217 | +0.007 | +4 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.217 | +0.014 | +7 |  |
| head.solid_width | 0.207 | 0.217 | +0.010 | +5 |  |
| head.extent | 0.331 | 0.275 | -0.056 | -17 |  |
| snout.outer_width | 0.195 | 0.205 | +0.010 | +5 |  |
| snout.solid_width | 0.194 | 0.205 | +0.011 | +6 |  |
| snout.extent | 0.258 | 0.229 | -0.029 | -11 |  |
| neck.outer_width | 0.198 | 0.184 | -0.014 | -7 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.183 | +0.005 | +3 | y |
| neck.solid_width | 0.191 | 0.184 | -0.007 | -4 |  |
| neck.extent | 0.458 | 0.397 | -0.061 | -13 |  |
| neck_top.outer_width | 0.142 | 0.136 | -0.006 | -4 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.137 | +0.003 | +2 | y |
| neck_top.solid_width | 0.138 | 0.136 | -0.001 | -1 |  |
| neck_top.extent | 0.224 | 0.179 | -0.045 | -20 |  |
| neck_mid.outer_width | 0.122 | 0.123 | +0.000 | +0 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.123 | +0.000 | +0 | y |
| neck_mid.solid_width | 0.122 | 0.123 | +0.000 | +0 |  |
| neck_mid.extent | 0.133 | 0.136 | +0.002 | +2 |  |
| neck_base.outer_width | 0.345 | 0.309 | -0.036 | -10 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.307 | -0.019 | -6 | y |
| neck_base.solid_width | 0.344 | 0.308 | -0.036 | -10 |  |
| neck_base.extent | 0.409 | 0.365 | -0.044 | -11 |  |
| shoulders.outer_width | 0.625 | 0.617 | -0.008 | -1 | y |
| shoulders.solid_width | 0.625 | 0.617 | -0.008 | -1 |  |
| shoulders.extent | 0.639 | 0.632 | -0.007 | -1 |  |
| torso.outer_width | 0.675 | 0.672 | -0.004 | -1 | y |
| torso.solid_width | 0.666 | 0.669 | +0.003 | +0 |  |
| torso.extent | 0.812 | 0.792 | -0.020 | -2 |  |
| waist.outer_width | 0.743 | 0.746 | +0.003 | +0 | y |
| waist.solid_width | 0.742 | 0.746 | +0.004 | +0 |  |
| waist.extent | 0.751 | 0.750 | -0.001 | -0 |  |
| pelvis.outer_width | 0.784 | 0.768 | -0.016 | -2 | y |
| pelvis.solid_width | 0.745 | 0.754 | +0.009 | +1 |  |
| pelvis.extent | 0.812 | 0.792 | -0.020 | -2 |  |
| arm.outer_width | 0.712 | 0.719 | +0.007 | +1 |  |
| arm.solid_width | 0.691 | 0.701 | +0.009 | +1 |  |
| arm.extent | 0.861 | 0.849 | -0.012 | -1 |  |
| hand.outer_width | 0.770 | 0.781 | +0.011 | +1 |  |
| hand.solid_width | 0.696 | 0.713 | +0.017 | +2 |  |
| hand.extent | 0.882 | 0.866 | -0.015 | -2 |  |
| thigh.outer_width | 0.755 | 0.767 | +0.012 | +2 | y |
| thigh.solid_width | 0.627 | 0.631 | +0.004 | +1 |  |
| thigh.extent | 0.889 | 0.866 | -0.023 | -3 |  |
| shin.outer_width | 0.606 | 0.612 | +0.007 | +1 | y |
| shin.solid_width | 0.350 | 0.337 | -0.013 | -4 |  |
| shin.extent | 0.668 | 0.663 | -0.004 | -1 |  |
| foot.outer_width | 0.708 | 0.727 | +0.019 | +3 | y |
| foot.solid_width | 0.357 | 0.371 | +0.014 | +4 |  |
| foot.extent | 0.829 | 0.797 | -0.033 | -4 |  |
| total_height (highest point) | 2.400 | 2.399 | -0.001 | -0 | y |
| horn_B(image-left).tip_height | 2.400 | 2.399 | -0.001 | -0 | y |
| horn_B(image-left).span | 0.290 | 0.278 | -0.012 | -4 | y |
| horn_A(image-right).tip_height | 2.362 | 2.367 | +0.005 | +0 | y |
| horn_A(image-right).span | 0.103 | 0.111 | +0.008 | +8 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.390 | -0.004 | -1 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.750 | -0.022 | -3 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 0.881 | +0.022 | +3 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.193 | -0.009 | -5 |  |
| horns.solid_width | 0.113 | 0.111 | -0.002 | -2 |  |
| horns.extent | 0.473 | 0.405 | -0.069 | -15 |  |
| head.outer_width | 0.323 | 0.217 | -0.106 | -33 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.217 | -0.041 | -16 |  |
| head.solid_width | 0.291 | 0.217 | -0.074 | -25 |  |
| head.extent | 0.484 | 0.275 | -0.209 | -43 |  |
| snout.outer_width | 0.319 | 0.205 | -0.115 | -36 |  |
| snout.solid_width | 0.300 | 0.205 | -0.095 | -32 |  |
| snout.extent | 0.444 | 0.228 | -0.216 | -49 |  |
| neck.outer_width | 0.220 | 0.184 | -0.037 | -17 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.183 | +0.028 | +18 | y |
| neck.solid_width | 0.193 | 0.183 | -0.009 | -5 |  |
| neck.extent | 0.509 | 0.397 | -0.112 | -22 |  |
| neck_top.outer_width | 0.178 | 0.136 | -0.042 | -24 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.137 | +0.002 | +2 | y |
| neck_top.solid_width | 0.145 | 0.136 | -0.009 | -6 |  |
| neck_top.extent | 0.270 | 0.179 | -0.092 | -34 |  |
| neck_mid.outer_width | 0.133 | 0.123 | -0.011 | -8 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.123 | -0.011 | -8 | y |
| neck_mid.solid_width | 0.133 | 0.123 | -0.011 | -8 |  |
| neck_mid.extent | 0.139 | 0.135 | -0.004 | -3 |  |
| neck_base.outer_width | 0.366 | 0.309 | -0.057 | -16 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.307 | +0.093 | +43 | y |
| neck_base.solid_width | 0.335 | 0.308 | -0.027 | -8 |  |
| neck_base.extent | 0.389 | 0.366 | -0.023 | -6 |  |
| shoulders.outer_width | 0.585 | 0.617 | +0.032 | +6 | y |
| shoulders.solid_width | 0.585 | 0.617 | +0.032 | +6 |  |
| shoulders.extent | 0.668 | 0.632 | -0.036 | -5 |  |
| torso.outer_width | 0.783 | 0.672 | -0.111 | -14 | y |
| torso.solid_width | 0.733 | 0.669 | -0.064 | -9 |  |
| torso.extent | 1.103 | 0.792 | -0.310 | -28 |  |
| waist.outer_width | 0.897 | 0.746 | -0.151 | -17 | y |
| waist.solid_width | 0.827 | 0.746 | -0.081 | -10 |  |
| waist.extent | 0.928 | 0.750 | -0.178 | -19 |  |
| pelvis.outer_width | 0.966 | 0.768 | -0.198 | -21 | y |
| pelvis.solid_width | 0.921 | 0.754 | -0.168 | -18 |  |
| pelvis.extent | 1.053 | 0.792 | -0.261 | -25 |  |
| arm.outer_width | 0.839 | 0.719 | -0.120 | -14 |  |
| arm.solid_width | 0.790 | 0.701 | -0.089 | -11 |  |
| arm.extent | 1.103 | 0.849 | -0.254 | -23 |  |
| hand.outer_width | 0.908 | 0.781 | -0.127 | -14 |  |
| hand.solid_width | 0.879 | 0.713 | -0.166 | -19 |  |
| hand.extent | 1.111 | 0.866 | -0.245 | -22 |  |
| thigh.outer_width | 0.867 | 0.767 | -0.100 | -12 | y |
| thigh.solid_width | 0.862 | 0.631 | -0.231 | -27 |  |
| thigh.extent | 0.914 | 0.866 | -0.047 | -5 |  |
| shin.outer_width | 0.839 | 0.612 | -0.227 | -27 | y |
| shin.solid_width | 0.564 | 0.336 | -0.228 | -40 |  |
| shin.extent | 0.939 | 0.663 | -0.277 | -29 |  |
| foot.outer_width | 0.681 | 0.727 | +0.045 | +7 | y |
| foot.solid_width | 0.387 | 0.371 | -0.016 | -4 |  |
| foot.extent | 0.936 | 0.796 | -0.140 | -15 |  |
| total_height (highest point) | 2.400 | 2.399 | -0.001 | -0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. side torso.chest_to_back_depth: ref 0.513 m, model 0.460 m, err -0.053 m (-10%)
2. side horn_A(rear/thick).tip_height: ref 2.400 m, model 2.367 m, err -0.033 m (-1%)
3. side horns.total_depth_spread (side): ref 0.334 m, model 0.357 m, err +0.022 m (+7%)
4. side horn_B(front/long).span: ref 0.183 m, model 0.202 m, err +0.020 m (+11%)
5. back neck_base.run_width (central run, fringe/skirt-free): ref 0.326 m, model 0.307 m, err -0.019 m (-6%)
6. back foot.outer_width: ref 0.708 m, model 0.727 m, err +0.019 m (+3%)
7. back pelvis.outer_width: ref 0.784 m, model 0.768 m, err -0.016 m (-2%)
8. side foot.outer_width: ref 0.235 m, model 0.250 m, err +0.015 m (+6%)
