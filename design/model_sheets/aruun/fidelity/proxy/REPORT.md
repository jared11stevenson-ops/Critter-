# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/proxy/proxy.glb`  forward +z  render height 2.393 m (top 2.398); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.808 | 0.805 | -0.006 | 1.09 | 0.164 | +0.023 |
| back | 0.835 | 0.835 | -0.002 | 0.99 | 0.128 | +0.012 |
| front (3/4 ref, qualitative) | 0.567 | 0.424 | +0.146 | 0.82 | 0.318 | -0.084 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.246 | +0.054 | +28 |  |
| horns.solid_width | 0.119 | 0.122 | +0.002 | +2 |  |
| horns.extent | 0.381 | 0.399 | +0.018 | +5 |  |
| head.outer_width | 0.226 | 0.240 | +0.014 | +6 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.227 | +0.027 | +14 |  |
| head.solid_width | 0.213 | 0.237 | +0.024 | +11 |  |
| head.extent | 0.307 | 0.312 | +0.005 | +2 |  |
| snout.outer_width | 0.236 | 0.256 | +0.020 | +8 |  |
| snout.solid_width | 0.218 | 0.255 | +0.037 | +17 |  |
| snout.extent | 0.307 | 0.312 | +0.005 | +2 |  |
| neck.outer_width | 0.150 | 0.172 | +0.021 | +14 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.171 | +0.024 | +16 | y |
| neck.solid_width | 0.149 | 0.172 | +0.022 | +15 |  |
| neck.extent | 0.314 | 0.261 | -0.053 | -17 |  |
| neck_top.outer_width | 0.108 | 0.104 | -0.004 | -4 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.104 | -0.004 | -4 | y |
| neck_top.solid_width | 0.108 | 0.104 | -0.004 | -4 |  |
| neck_top.extent | 0.110 | 0.118 | +0.008 | +7 |  |
| neck_mid.outer_width | 0.115 | 0.179 | +0.064 | +56 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.178 | +0.063 | +55 | y |
| neck_mid.solid_width | 0.115 | 0.179 | +0.064 | +56 |  |
| neck_mid.extent | 0.124 | 0.205 | +0.081 | +65 |  |
| neck_base.outer_width | 0.252 | 0.238 | -0.014 | -6 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.238 | -0.007 | -3 | y |
| neck_base.solid_width | 0.250 | 0.238 | -0.012 | -5 |  |
| neck_base.extent | 0.314 | 0.261 | -0.053 | -17 |  |
| shoulders.outer_width | 0.402 | 0.420 | +0.018 | +5 | y |
| shoulders.solid_width | 0.402 | 0.420 | +0.018 | +5 |  |
| shoulders.extent | 0.436 | 0.459 | +0.023 | +5 |  |
| torso.outer_width | 0.423 | 0.442 | +0.018 | +4 |  |
| torso.solid_width | 0.413 | 0.442 | +0.029 | +7 |  |
| torso.extent | 0.537 | 0.515 | -0.022 | -4 |  |
| waist.outer_width | 0.460 | 0.451 | -0.010 | -2 | y |
| waist.solid_width | 0.460 | 0.451 | -0.010 | -2 |  |
| waist.extent | 0.468 | 0.453 | -0.015 | -3 |  |
| pelvis.outer_width | 0.419 | 0.401 | -0.018 | -4 |  |
| pelvis.solid_width | 0.405 | 0.401 | -0.004 | -1 |  |
| pelvis.extent | 0.446 | 0.433 | -0.012 | -3 |  |
| arm.outer_width | 0.399 | 0.423 | +0.024 | +6 |  |
| arm.solid_width | 0.387 | 0.423 | +0.036 | +9 |  |
| arm.extent | 0.537 | 0.515 | -0.022 | -4 |  |
| hand.outer_width | 0.302 | 0.316 | +0.014 | +5 |  |
| hand.solid_width | 0.294 | 0.316 | +0.022 | +7 |  |
| hand.extent | 0.463 | 0.452 | -0.010 | -2 |  |
| thigh.outer_width | 0.192 | 0.230 | +0.039 | +20 |  |
| thigh.solid_width | 0.187 | 0.230 | +0.043 | +23 |  |
| thigh.extent | 0.360 | 0.353 | -0.007 | -2 |  |
| shin.outer_width | 0.117 | 0.133 | +0.015 | +13 | y |
| shin.solid_width | 0.117 | 0.133 | +0.015 | +13 |  |
| shin.extent | 0.198 | 0.214 | +0.016 | +8 |  |
| foot.outer_width | 0.235 | 0.243 | +0.008 | +3 | y |
| foot.solid_width | 0.229 | 0.235 | +0.006 | +3 |  |
| foot.extent | 0.416 | 0.420 | +0.004 | +1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.129 | -0.002 | -1 | y |
| head.length (nape..snout tip) | 0.307 | 0.312 | +0.005 | +2 | y |
| foot.length (heel..toe) | 0.416 | 0.420 | +0.004 | +1 | y |
| torso.chest_to_back_depth | 0.513 | 0.515 | +0.002 | +0 | y |
| head.snout_tip_height | 2.008 | 2.011 | +0.004 | +0 |  |
| total_height (highest point) | 2.400 | 2.398 | -0.002 | -0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.398 | -0.002 | -0 | y |
| horn_A(rear/thick).span | 0.217 | 0.229 | +0.012 | +5 | y |
| horn_B(front/long).tip_height | 2.391 | 2.395 | +0.004 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.194 | +0.011 | +6 | y |
| horns.total_depth_spread (side) | 0.334 | 0.393 | +0.058 | +17 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.233 | +0.043 | +22 |  |
| horns.solid_width | 0.119 | 0.109 | -0.010 | -9 |  |
| horns.extent | 0.439 | 0.372 | -0.067 | -15 |  |
| head.outer_width | 0.210 | 0.183 | -0.027 | -13 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.183 | -0.021 | -10 |  |
| head.solid_width | 0.207 | 0.183 | -0.024 | -12 |  |
| head.extent | 0.331 | 0.219 | -0.111 | -34 |  |
| snout.outer_width | 0.195 | 0.184 | -0.011 | -5 |  |
| snout.solid_width | 0.194 | 0.184 | -0.010 | -5 |  |
| snout.extent | 0.258 | 0.219 | -0.038 | -15 |  |
| neck.outer_width | 0.198 | 0.187 | -0.011 | -5 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.187 | +0.009 | +5 | y |
| neck.solid_width | 0.191 | 0.187 | -0.004 | -2 |  |
| neck.extent | 0.458 | 0.353 | -0.105 | -23 |  |
| neck_top.outer_width | 0.142 | 0.123 | -0.020 | -14 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.123 | -0.011 | -8 | y |
| neck_top.solid_width | 0.138 | 0.123 | -0.015 | -11 |  |
| neck_top.extent | 0.224 | 0.138 | -0.087 | -39 |  |
| neck_mid.outer_width | 0.122 | 0.156 | +0.033 | +27 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.156 | +0.033 | +27 | y |
| neck_mid.solid_width | 0.122 | 0.156 | +0.033 | +27 |  |
| neck_mid.extent | 0.133 | 0.184 | +0.050 | +38 |  |
| neck_base.outer_width | 0.345 | 0.301 | -0.044 | -13 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.301 | -0.025 | -8 | y |
| neck_base.solid_width | 0.344 | 0.301 | -0.043 | -12 |  |
| neck_base.extent | 0.409 | 0.347 | -0.062 | -15 |  |
| shoulders.outer_width | 0.625 | 0.596 | -0.029 | -5 | y |
| shoulders.solid_width | 0.625 | 0.596 | -0.029 | -5 |  |
| shoulders.extent | 0.639 | 0.620 | -0.018 | -3 |  |
| torso.outer_width | 0.675 | 0.697 | +0.022 | +3 | y |
| torso.solid_width | 0.666 | 0.692 | +0.026 | +4 |  |
| torso.extent | 0.812 | 0.869 | +0.057 | +7 |  |
| waist.outer_width | 0.743 | 0.768 | +0.025 | +3 | y |
| waist.solid_width | 0.742 | 0.767 | +0.025 | +3 |  |
| waist.extent | 0.751 | 0.773 | +0.022 | +3 |  |
| pelvis.outer_width | 0.784 | 0.820 | +0.036 | +5 | y |
| pelvis.solid_width | 0.745 | 0.804 | +0.059 | +8 |  |
| pelvis.extent | 0.812 | 0.869 | +0.057 | +7 |  |
| arm.outer_width | 0.712 | 0.755 | +0.042 | +6 |  |
| arm.solid_width | 0.691 | 0.733 | +0.042 | +6 |  |
| arm.extent | 0.861 | 0.872 | +0.011 | +1 |  |
| hand.outer_width | 0.770 | 0.811 | +0.041 | +5 |  |
| hand.solid_width | 0.696 | 0.740 | +0.044 | +6 |  |
| hand.extent | 0.882 | 0.872 | -0.010 | -1 |  |
| thigh.outer_width | 0.755 | 0.760 | +0.005 | +1 | y |
| thigh.solid_width | 0.627 | 0.617 | -0.011 | -2 |  |
| thigh.extent | 0.889 | 0.870 | -0.018 | -2 |  |
| shin.outer_width | 0.606 | 0.620 | +0.014 | +2 | y |
| shin.solid_width | 0.350 | 0.300 | -0.050 | -14 |  |
| shin.extent | 0.668 | 0.666 | -0.001 | -0 |  |
| foot.outer_width | 0.708 | 0.702 | -0.006 | -1 | y |
| foot.solid_width | 0.357 | 0.349 | -0.008 | -2 |  |
| foot.extent | 0.829 | 0.781 | -0.048 | -6 |  |
| total_height (highest point) | 2.400 | 2.398 | -0.002 | -0 | y |
| horn_B(image-left).tip_height | 2.400 | 2.395 | -0.005 | -0 | y |
| horn_B(image-left).span | 0.290 | 0.203 | -0.087 | -30 | y |
| horn_A(image-right).tip_height | 2.362 | 2.398 | +0.036 | +2 | y |
| horn_A(image-right).span | 0.103 | 0.056 | -0.047 | -46 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.368 | -0.026 | -7 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.750 | -0.022 | -3 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 0.881 | +0.022 | +3 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.233 | +0.031 | +15 |  |
| horns.solid_width | 0.113 | 0.109 | -0.004 | -4 |  |
| horns.extent | 0.473 | 0.372 | -0.101 | -21 |  |
| head.outer_width | 0.323 | 0.183 | -0.140 | -43 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.183 | -0.076 | -29 |  |
| head.solid_width | 0.291 | 0.183 | -0.108 | -37 |  |
| head.extent | 0.484 | 0.219 | -0.264 | -55 |  |
| snout.outer_width | 0.319 | 0.184 | -0.135 | -42 |  |
| snout.solid_width | 0.300 | 0.184 | -0.116 | -39 |  |
| snout.extent | 0.444 | 0.219 | -0.225 | -51 |  |
| neck.outer_width | 0.220 | 0.187 | -0.033 | -15 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.187 | +0.032 | +21 | y |
| neck.solid_width | 0.193 | 0.187 | -0.006 | -3 |  |
| neck.extent | 0.509 | 0.353 | -0.156 | -31 |  |
| neck_top.outer_width | 0.178 | 0.123 | -0.055 | -31 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.123 | -0.012 | -9 | y |
| neck_top.solid_width | 0.145 | 0.123 | -0.022 | -15 |  |
| neck_top.extent | 0.270 | 0.138 | -0.133 | -49 |  |
| neck_mid.outer_width | 0.133 | 0.156 | +0.023 | +17 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.156 | +0.022 | +17 | y |
| neck_mid.solid_width | 0.133 | 0.156 | +0.023 | +17 |  |
| neck_mid.extent | 0.139 | 0.184 | +0.045 | +33 |  |
| neck_base.outer_width | 0.366 | 0.301 | -0.065 | -18 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.301 | +0.087 | +41 | y |
| neck_base.solid_width | 0.335 | 0.301 | -0.034 | -10 |  |
| neck_base.extent | 0.389 | 0.346 | -0.042 | -11 |  |
| shoulders.outer_width | 0.585 | 0.596 | +0.011 | +2 | y |
| shoulders.solid_width | 0.585 | 0.596 | +0.011 | +2 |  |
| shoulders.extent | 0.668 | 0.620 | -0.048 | -7 |  |
| torso.outer_width | 0.783 | 0.697 | -0.086 | -11 | y |
| torso.solid_width | 0.733 | 0.692 | -0.041 | -6 |  |
| torso.extent | 1.103 | 0.870 | -0.233 | -21 |  |
| waist.outer_width | 0.897 | 0.768 | -0.129 | -14 | y |
| waist.solid_width | 0.827 | 0.767 | -0.059 | -7 |  |
| waist.extent | 0.928 | 0.774 | -0.154 | -17 |  |
| pelvis.outer_width | 0.966 | 0.820 | -0.146 | -15 | y |
| pelvis.solid_width | 0.921 | 0.804 | -0.117 | -13 |  |
| pelvis.extent | 1.053 | 0.870 | -0.183 | -17 |  |
| arm.outer_width | 0.839 | 0.755 | -0.085 | -10 |  |
| arm.solid_width | 0.790 | 0.733 | -0.056 | -7 |  |
| arm.extent | 1.103 | 0.872 | -0.231 | -21 |  |
| hand.outer_width | 0.908 | 0.811 | -0.098 | -11 |  |
| hand.solid_width | 0.879 | 0.740 | -0.139 | -16 |  |
| hand.extent | 1.111 | 0.872 | -0.240 | -22 |  |
| thigh.outer_width | 0.867 | 0.760 | -0.107 | -12 | y |
| thigh.solid_width | 0.862 | 0.617 | -0.245 | -28 |  |
| thigh.extent | 0.914 | 0.870 | -0.043 | -5 |  |
| shin.outer_width | 0.839 | 0.620 | -0.219 | -26 | y |
| shin.solid_width | 0.564 | 0.300 | -0.264 | -47 |  |
| shin.extent | 0.939 | 0.666 | -0.273 | -29 |  |
| foot.outer_width | 0.681 | 0.702 | +0.021 | +3 | y |
| foot.solid_width | 0.387 | 0.349 | -0.038 | -10 |  |
| foot.extent | 0.936 | 0.781 | -0.154 | -16 |  |
| total_height (highest point) | 2.400 | 2.398 | -0.002 | -0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. back horn_B(image-left).span: ref 0.290 m, model 0.203 m, err -0.087 m (-30%)
2. side neck_mid.run_width (central run, fringe/skirt-free): ref 0.115 m, model 0.178 m, err +0.063 m (+55%)
3. side horns.total_depth_spread (side): ref 0.334 m, model 0.393 m, err +0.058 m (+17%)
4. back horn_A(image-right).span: ref 0.103 m, model 0.056 m, err -0.047 m (-46%)
5. back pelvis.outer_width: ref 0.784 m, model 0.820 m, err +0.036 m (+5%)
6. back horn_A(image-right).tip_height: ref 2.362 m, model 2.398 m, err +0.036 m (+2%)
7. back neck_mid.run_width (central run, fringe/skirt-free): ref 0.122 m, model 0.156 m, err +0.033 m (+27%)
8. back shoulders.outer_width: ref 0.625 m, model 0.596 m, err -0.029 m (-5%)
