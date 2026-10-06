# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/proxy/proxy.glb`  forward +z  render height 2.390 m (top 2.401); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.794 | 0.793 | -0.004 | 1.10 | 0.167 | +0.016 |
| back | 0.815 | 0.815 | +0.000 | 1.04 | 0.121 | +0.028 |
| front (3/4 ref, qualitative) | 0.590 | 0.438 | +0.154 | 0.86 | 0.265 | -0.068 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.146 | -0.047 | -25 |  |
| horns.solid_width | 0.119 | 0.117 | -0.003 | -2 |  |
| horns.extent | 0.381 | 0.384 | +0.003 | +1 |  |
| head.outer_width | 0.226 | 0.236 | +0.009 | +4 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.233 | +0.033 | +17 |  |
| head.solid_width | 0.213 | 0.235 | +0.022 | +10 |  |
| head.extent | 0.307 | 0.314 | +0.006 | +2 |  |
| snout.outer_width | 0.236 | 0.256 | +0.020 | +8 |  |
| snout.solid_width | 0.218 | 0.256 | +0.037 | +17 |  |
| snout.extent | 0.307 | 0.314 | +0.006 | +2 |  |
| neck.outer_width | 0.150 | 0.168 | +0.018 | +12 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.168 | +0.020 | +14 | y |
| neck.solid_width | 0.149 | 0.168 | +0.019 | +13 |  |
| neck.extent | 0.314 | 0.279 | -0.034 | -11 |  |
| neck_top.outer_width | 0.108 | 0.105 | -0.003 | -3 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.105 | -0.003 | -3 | y |
| neck_top.solid_width | 0.108 | 0.105 | -0.003 | -3 |  |
| neck_top.extent | 0.110 | 0.119 | +0.009 | +8 |  |
| neck_mid.outer_width | 0.115 | 0.166 | +0.051 | +44 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.165 | +0.051 | +44 | y |
| neck_mid.solid_width | 0.115 | 0.166 | +0.051 | +44 |  |
| neck_mid.extent | 0.124 | 0.193 | +0.069 | +55 |  |
| neck_base.outer_width | 0.252 | 0.243 | -0.009 | -4 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.243 | -0.002 | -1 | y |
| neck_base.solid_width | 0.250 | 0.243 | -0.007 | -3 |  |
| neck_base.extent | 0.314 | 0.279 | -0.034 | -11 |  |
| shoulders.outer_width | 0.402 | 0.436 | +0.034 | +8 | y |
| shoulders.solid_width | 0.402 | 0.436 | +0.034 | +8 |  |
| shoulders.extent | 0.436 | 0.472 | +0.035 | +8 |  |
| torso.outer_width | 0.423 | 0.456 | +0.032 | +8 |  |
| torso.solid_width | 0.413 | 0.456 | +0.043 | +10 |  |
| torso.extent | 0.537 | 0.527 | -0.010 | -2 |  |
| waist.outer_width | 0.460 | 0.458 | -0.003 | -1 | y |
| waist.solid_width | 0.460 | 0.458 | -0.003 | -1 |  |
| waist.extent | 0.468 | 0.460 | -0.007 | -2 |  |
| pelvis.outer_width | 0.419 | 0.426 | +0.007 | +2 |  |
| pelvis.solid_width | 0.405 | 0.426 | +0.021 | +5 |  |
| pelvis.extent | 0.446 | 0.445 | -0.001 | -0 |  |
| arm.outer_width | 0.399 | 0.438 | +0.039 | +10 |  |
| arm.solid_width | 0.387 | 0.438 | +0.051 | +13 |  |
| arm.extent | 0.537 | 0.527 | -0.010 | -2 |  |
| hand.outer_width | 0.302 | 0.335 | +0.033 | +11 |  |
| hand.solid_width | 0.294 | 0.335 | +0.040 | +14 |  |
| hand.extent | 0.463 | 0.461 | -0.002 | -0 |  |
| thigh.outer_width | 0.192 | 0.235 | +0.043 | +22 |  |
| thigh.solid_width | 0.187 | 0.234 | +0.047 | +25 |  |
| thigh.extent | 0.360 | 0.408 | +0.049 | +14 |  |
| shin.outer_width | 0.117 | 0.135 | +0.017 | +15 | y |
| shin.solid_width | 0.117 | 0.135 | +0.017 | +15 |  |
| shin.extent | 0.198 | 0.211 | +0.013 | +7 |  |
| foot.outer_width | 0.235 | 0.230 | -0.005 | -2 | y |
| foot.solid_width | 0.229 | 0.218 | -0.010 | -5 |  |
| foot.extent | 0.416 | 0.421 | +0.006 | +1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.131 | +0.001 | +0 | y |
| head.length (nape..snout tip) | 0.307 | 0.314 | +0.006 | +2 | y |
| foot.length (heel..toe) | 0.416 | 0.421 | +0.006 | +1 | y |
| torso.chest_to_back_depth | 0.513 | 0.526 | +0.012 | +2 | y |
| head.snout_tip_height | 2.008 | 2.011 | +0.004 | +0 |  |
| total_height (highest point) | 2.400 | 2.401 | +0.001 | +0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.377 | -0.023 | -1 | y |
| horn_A(rear/thick).span | 0.217 | 0.184 | -0.033 | -15 | y |
| horn_B(front/long).tip_height | 2.391 | 2.400 | +0.009 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.264 | +0.081 | +44 | y |
| horns.total_depth_spread (side) | 0.334 | 0.355 | +0.021 | +6 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.206 | +0.015 | +8 |  |
| horns.solid_width | 0.119 | 0.105 | -0.014 | -12 |  |
| horns.extent | 0.439 | 0.382 | -0.057 | -13 |  |
| head.outer_width | 0.210 | 0.188 | -0.022 | -11 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.187 | -0.017 | -8 |  |
| head.solid_width | 0.207 | 0.187 | -0.020 | -9 |  |
| head.extent | 0.331 | 0.242 | -0.089 | -27 |  |
| snout.outer_width | 0.195 | 0.184 | -0.011 | -6 |  |
| snout.solid_width | 0.194 | 0.184 | -0.010 | -5 |  |
| snout.extent | 0.258 | 0.219 | -0.038 | -15 |  |
| neck.outer_width | 0.198 | 0.226 | +0.028 | +14 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.225 | +0.048 | +27 | y |
| neck.solid_width | 0.191 | 0.226 | +0.035 | +18 |  |
| neck.extent | 0.458 | 0.420 | -0.037 | -8 |  |
| neck_top.outer_width | 0.142 | 0.119 | -0.024 | -17 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.119 | -0.015 | -11 | y |
| neck_top.solid_width | 0.138 | 0.119 | -0.019 | -14 |  |
| neck_top.extent | 0.224 | 0.136 | -0.088 | -39 |  |
| neck_mid.outer_width | 0.122 | 0.198 | +0.076 | +62 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.198 | +0.076 | +62 | y |
| neck_mid.solid_width | 0.122 | 0.198 | +0.076 | +62 |  |
| neck_mid.extent | 0.133 | 0.256 | +0.122 | +92 |  |
| neck_base.outer_width | 0.345 | 0.376 | +0.030 | +9 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.375 | +0.049 | +15 | y |
| neck_base.solid_width | 0.344 | 0.376 | +0.032 | +9 |  |
| neck_base.extent | 0.409 | 0.420 | +0.012 | +3 |  |
| shoulders.outer_width | 0.625 | 0.606 | -0.018 | -3 | y |
| shoulders.solid_width | 0.625 | 0.606 | -0.018 | -3 |  |
| shoulders.extent | 0.639 | 0.625 | -0.014 | -2 |  |
| torso.outer_width | 0.675 | 0.718 | +0.043 | +6 | y |
| torso.solid_width | 0.666 | 0.712 | +0.046 | +7 |  |
| torso.extent | 0.812 | 0.861 | +0.049 | +6 |  |
| waist.outer_width | 0.743 | 0.781 | +0.038 | +5 | y |
| waist.solid_width | 0.742 | 0.770 | +0.028 | +4 |  |
| waist.extent | 0.751 | 0.784 | +0.033 | +4 |  |
| pelvis.outer_width | 0.784 | 0.805 | +0.021 | +3 | y |
| pelvis.solid_width | 0.745 | 0.792 | +0.047 | +6 |  |
| pelvis.extent | 0.812 | 0.861 | +0.049 | +6 |  |
| arm.outer_width | 0.712 | 0.768 | +0.056 | +8 |  |
| arm.solid_width | 0.691 | 0.746 | +0.054 | +8 |  |
| arm.extent | 0.861 | 0.869 | +0.009 | +1 |  |
| hand.outer_width | 0.770 | 0.808 | +0.038 | +5 |  |
| hand.solid_width | 0.696 | 0.740 | +0.044 | +6 |  |
| hand.extent | 0.882 | 0.871 | -0.010 | -1 |  |
| thigh.outer_width | 0.755 | 0.777 | +0.022 | +3 | y |
| thigh.solid_width | 0.627 | 0.645 | +0.017 | +3 |  |
| thigh.extent | 0.889 | 0.871 | -0.018 | -2 |  |
| shin.outer_width | 0.606 | 0.673 | +0.067 | +11 | y |
| shin.solid_width | 0.350 | 0.359 | +0.009 | +3 |  |
| shin.extent | 0.668 | 0.736 | +0.068 | +10 |  |
| foot.outer_width | 0.708 | 0.680 | -0.028 | -4 | y |
| foot.solid_width | 0.357 | 0.335 | -0.022 | -6 |  |
| foot.extent | 0.829 | 0.832 | +0.003 | +0 |  |
| total_height (highest point) | 2.400 | 2.401 | +0.001 | +0 | y |
| horn_B(image-left).tip_height | 2.400 | 2.400 | +0.000 | +0 | y |
| horn_B(image-left).span | 0.290 | 0.227 | -0.063 | -22 | y |
| horn_A(image-right).tip_height | 2.362 | 2.377 | +0.015 | +1 | y |
| horn_A(image-right).span | 0.103 | 0.050 | -0.053 | -51 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.381 | -0.013 | -3 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.750 | -0.022 | -3 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 0.881 | +0.022 | +3 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.206 | +0.003 | +2 |  |
| horns.solid_width | 0.113 | 0.105 | -0.008 | -7 |  |
| horns.extent | 0.473 | 0.382 | -0.091 | -19 |  |
| head.outer_width | 0.323 | 0.188 | -0.136 | -42 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.185 | -0.074 | -28 |  |
| head.solid_width | 0.291 | 0.188 | -0.104 | -36 |  |
| head.extent | 0.484 | 0.242 | -0.242 | -50 |  |
| snout.outer_width | 0.319 | 0.184 | -0.136 | -42 |  |
| snout.solid_width | 0.300 | 0.184 | -0.116 | -39 |  |
| snout.extent | 0.444 | 0.219 | -0.225 | -51 |  |
| neck.outer_width | 0.220 | 0.226 | +0.006 | +3 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.225 | +0.071 | +46 | y |
| neck.solid_width | 0.193 | 0.226 | +0.033 | +17 |  |
| neck.extent | 0.509 | 0.420 | -0.089 | -17 |  |
| neck_top.outer_width | 0.178 | 0.119 | -0.059 | -33 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.119 | -0.016 | -12 | y |
| neck_top.solid_width | 0.145 | 0.119 | -0.026 | -18 |  |
| neck_top.extent | 0.270 | 0.136 | -0.134 | -50 |  |
| neck_mid.outer_width | 0.133 | 0.199 | +0.065 | +49 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.198 | +0.065 | +49 | y |
| neck_mid.solid_width | 0.133 | 0.199 | +0.065 | +49 |  |
| neck_mid.extent | 0.139 | 0.256 | +0.117 | +84 |  |
| neck_base.outer_width | 0.366 | 0.376 | +0.009 | +2 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.375 | +0.162 | +76 | y |
| neck_base.solid_width | 0.335 | 0.376 | +0.040 | +12 |  |
| neck_base.extent | 0.389 | 0.420 | +0.032 | +8 |  |
| shoulders.outer_width | 0.585 | 0.606 | +0.022 | +4 | y |
| shoulders.solid_width | 0.585 | 0.606 | +0.022 | +4 |  |
| shoulders.extent | 0.668 | 0.625 | -0.044 | -7 |  |
| torso.outer_width | 0.783 | 0.718 | -0.064 | -8 | y |
| torso.solid_width | 0.733 | 0.712 | -0.021 | -3 |  |
| torso.extent | 1.103 | 0.861 | -0.242 | -22 |  |
| waist.outer_width | 0.897 | 0.781 | -0.116 | -13 | y |
| waist.solid_width | 0.827 | 0.770 | -0.057 | -7 |  |
| waist.extent | 0.928 | 0.784 | -0.144 | -15 |  |
| pelvis.outer_width | 0.966 | 0.805 | -0.162 | -17 | y |
| pelvis.solid_width | 0.921 | 0.792 | -0.129 | -14 |  |
| pelvis.extent | 1.053 | 0.861 | -0.192 | -18 |  |
| arm.outer_width | 0.839 | 0.768 | -0.072 | -9 |  |
| arm.solid_width | 0.790 | 0.746 | -0.044 | -6 |  |
| arm.extent | 1.103 | 0.869 | -0.234 | -21 |  |
| hand.outer_width | 0.908 | 0.808 | -0.100 | -11 |  |
| hand.solid_width | 0.879 | 0.740 | -0.139 | -16 |  |
| hand.extent | 1.111 | 0.871 | -0.240 | -22 |  |
| thigh.outer_width | 0.867 | 0.777 | -0.090 | -10 | y |
| thigh.solid_width | 0.862 | 0.645 | -0.217 | -25 |  |
| thigh.extent | 0.914 | 0.871 | -0.042 | -5 |  |
| shin.outer_width | 0.839 | 0.673 | -0.166 | -20 | y |
| shin.solid_width | 0.564 | 0.359 | -0.205 | -36 |  |
| shin.extent | 0.939 | 0.735 | -0.204 | -22 |  |
| foot.outer_width | 0.681 | 0.680 | -0.002 | -0 | y |
| foot.solid_width | 0.387 | 0.335 | -0.051 | -13 |  |
| foot.extent | 0.936 | 0.832 | -0.103 | -11 |  |
| total_height (highest point) | 2.400 | 2.401 | +0.001 | +0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. side horn_B(front/long).span: ref 0.183 m, model 0.264 m, err +0.081 m (+44%)
2. back neck_mid.run_width (central run, fringe/skirt-free): ref 0.122 m, model 0.198 m, err +0.076 m (+62%)
3. back shin.outer_width: ref 0.606 m, model 0.673 m, err +0.067 m (+11%)
4. back horn_B(image-left).span: ref 0.290 m, model 0.227 m, err -0.063 m (-22%)
5. back horn_A(image-right).span: ref 0.103 m, model 0.050 m, err -0.053 m (-51%)
6. side neck_mid.run_width (central run, fringe/skirt-free): ref 0.115 m, model 0.165 m, err +0.051 m (+44%)
7. back neck_base.run_width (central run, fringe/skirt-free): ref 0.326 m, model 0.375 m, err +0.049 m (+15%)
8. back neck.run_width (central run, fringe/skirt-free): ref 0.178 m, model 0.225 m, err +0.048 m (+27%)
