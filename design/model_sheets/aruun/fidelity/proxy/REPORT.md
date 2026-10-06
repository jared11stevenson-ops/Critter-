# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/proxy/proxy.glb`  forward +z  render height 2.400 m (top 2.400); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.859 | 0.857 | -0.002 | 1.05 | 0.106 | +0.005 |
| back | 0.855 | 0.855 | +0.001 | 1.00 | 0.086 | +0.008 |
| front (3/4 ref, qualitative) | 0.572 | 0.421 | +0.152 | 0.83 | 0.301 | -0.088 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.184 | -0.009 | -5 |  |
| horns.solid_width | 0.119 | 0.124 | +0.004 | +4 |  |
| horns.extent | 0.381 | 0.379 | -0.002 | -0 |  |
| head.outer_width | 0.226 | 0.248 | +0.021 | +9 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.244 | +0.044 | +22 |  |
| head.solid_width | 0.213 | 0.247 | +0.034 | +16 |  |
| head.extent | 0.307 | 0.302 | -0.005 | -2 |  |
| snout.outer_width | 0.236 | 0.254 | +0.018 | +7 |  |
| snout.solid_width | 0.218 | 0.254 | +0.035 | +16 |  |
| snout.extent | 0.307 | 0.302 | -0.005 | -2 |  |
| neck.outer_width | 0.150 | 0.179 | +0.029 | +19 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.179 | +0.032 | +22 | y |
| neck.solid_width | 0.149 | 0.179 | +0.030 | +20 |  |
| neck.extent | 0.314 | 0.317 | +0.004 | +1 |  |
| neck_top.outer_width | 0.108 | 0.116 | +0.007 | +7 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.116 | +0.007 | +7 | y |
| neck_top.solid_width | 0.108 | 0.116 | +0.007 | +7 |  |
| neck_top.extent | 0.110 | 0.136 | +0.026 | +24 |  |
| neck_mid.outer_width | 0.115 | 0.144 | +0.029 | +26 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.144 | +0.029 | +25 | y |
| neck_mid.solid_width | 0.115 | 0.144 | +0.029 | +26 |  |
| neck_mid.extent | 0.124 | 0.196 | +0.072 | +58 |  |
| neck_base.outer_width | 0.252 | 0.292 | +0.041 | +16 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.292 | +0.047 | +19 | y |
| neck_base.solid_width | 0.250 | 0.292 | +0.043 | +17 |  |
| neck_base.extent | 0.314 | 0.317 | +0.004 | +1 |  |
| shoulders.outer_width | 0.402 | 0.435 | +0.033 | +8 | y |
| shoulders.solid_width | 0.402 | 0.435 | +0.033 | +8 |  |
| shoulders.extent | 0.436 | 0.447 | +0.010 | +2 |  |
| torso.outer_width | 0.423 | 0.418 | -0.005 | -1 |  |
| torso.solid_width | 0.413 | 0.418 | +0.006 | +1 |  |
| torso.extent | 0.537 | 0.471 | -0.066 | -12 |  |
| waist.outer_width | 0.460 | 0.441 | -0.020 | -4 | y |
| waist.solid_width | 0.460 | 0.441 | -0.020 | -4 |  |
| waist.extent | 0.468 | 0.444 | -0.024 | -5 |  |
| pelvis.outer_width | 0.419 | 0.405 | -0.015 | -4 |  |
| pelvis.solid_width | 0.405 | 0.405 | -0.000 | -0 |  |
| pelvis.extent | 0.446 | 0.435 | -0.011 | -2 |  |
| arm.outer_width | 0.399 | 0.392 | -0.007 | -2 |  |
| arm.solid_width | 0.387 | 0.391 | +0.004 | +1 |  |
| arm.extent | 0.537 | 0.471 | -0.066 | -12 |  |
| hand.outer_width | 0.302 | 0.308 | +0.006 | +2 |  |
| hand.solid_width | 0.294 | 0.306 | +0.012 | +4 |  |
| hand.extent | 0.463 | 0.454 | -0.009 | -2 |  |
| thigh.outer_width | 0.192 | 0.212 | +0.020 | +11 |  |
| thigh.solid_width | 0.187 | 0.211 | +0.023 | +12 |  |
| thigh.extent | 0.360 | 0.360 | +0.001 | +0 |  |
| shin.outer_width | 0.117 | 0.124 | +0.007 | +6 | y |
| shin.solid_width | 0.117 | 0.124 | +0.007 | +6 |  |
| shin.extent | 0.198 | 0.200 | +0.002 | +1 |  |
| foot.outer_width | 0.235 | 0.239 | +0.004 | +2 | y |
| foot.solid_width | 0.229 | 0.239 | +0.010 | +4 |  |
| foot.extent | 0.416 | 0.411 | -0.005 | -1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.127 | -0.003 | -2 | y |
| head.length (nape..snout tip) | 0.307 | 0.302 | -0.005 | -2 | y |
| foot.length (heel..toe) | 0.416 | 0.411 | -0.005 | -1 | y |
| torso.chest_to_back_depth | 0.513 | 0.460 | -0.053 | -10 | y |
| head.snout_tip_height | 2.008 | 2.011 | +0.004 | +0 |  |
| total_height (highest point) | 2.400 | 2.400 | +0.000 | +0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.361 | -0.039 | -2 | y |
| horn_A(rear/thick).span | 0.217 | 0.213 | -0.004 | -2 | y |
| horn_B(front/long).tip_height | 2.391 | 2.400 | +0.009 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.227 | +0.045 | +25 | y |
| horns.total_depth_spread (side) | 0.334 | 0.369 | +0.034 | +10 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.193 | +0.003 | +1 |  |
| horns.solid_width | 0.119 | 0.105 | -0.014 | -12 |  |
| horns.extent | 0.439 | 0.367 | -0.072 | -16 |  |
| head.outer_width | 0.210 | 0.216 | +0.006 | +3 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.216 | +0.012 | +6 |  |
| head.solid_width | 0.207 | 0.216 | +0.009 | +4 |  |
| head.extent | 0.331 | 0.320 | -0.010 | -3 |  |
| snout.outer_width | 0.195 | 0.200 | +0.005 | +3 |  |
| snout.solid_width | 0.194 | 0.200 | +0.006 | +3 |  |
| snout.extent | 0.258 | 0.239 | -0.018 | -7 |  |
| neck.outer_width | 0.198 | 0.267 | +0.069 | +35 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.247 | +0.069 | +39 | y |
| neck.solid_width | 0.191 | 0.255 | +0.064 | +34 |  |
| neck.extent | 0.458 | 0.492 | +0.034 | +7 |  |
| neck_top.outer_width | 0.142 | 0.141 | -0.002 | -1 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.141 | +0.007 | +6 | y |
| neck_top.solid_width | 0.138 | 0.141 | +0.003 | +2 |  |
| neck_top.extent | 0.224 | 0.177 | -0.047 | -21 |  |
| neck_mid.outer_width | 0.122 | 0.211 | +0.089 | +73 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.144 | +0.022 | +18 | y |
| neck_mid.solid_width | 0.122 | 0.164 | +0.042 | +34 |  |
| neck_mid.extent | 0.133 | 0.335 | +0.202 | +151 |  |
| neck_base.outer_width | 0.345 | 0.461 | +0.116 | +33 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.461 | +0.135 | +41 | y |
| neck_base.solid_width | 0.344 | 0.461 | +0.117 | +34 |  |
| neck_base.extent | 0.409 | 0.492 | +0.083 | +20 |  |
| shoulders.outer_width | 0.625 | 0.623 | -0.002 | -0 | y |
| shoulders.solid_width | 0.625 | 0.623 | -0.002 | -0 |  |
| shoulders.extent | 0.639 | 0.632 | -0.007 | -1 |  |
| torso.outer_width | 0.675 | 0.683 | +0.008 | +1 | y |
| torso.solid_width | 0.666 | 0.680 | +0.014 | +2 |  |
| torso.extent | 0.812 | 0.806 | -0.006 | -1 |  |
| waist.outer_width | 0.743 | 0.746 | +0.004 | +1 | y |
| waist.solid_width | 0.742 | 0.746 | +0.004 | +1 |  |
| waist.extent | 0.751 | 0.751 | -0.001 | -0 |  |
| pelvis.outer_width | 0.784 | 0.775 | -0.009 | -1 | y |
| pelvis.solid_width | 0.745 | 0.761 | +0.017 | +2 |  |
| pelvis.extent | 0.812 | 0.806 | -0.006 | -1 |  |
| arm.outer_width | 0.712 | 0.723 | +0.011 | +2 |  |
| arm.solid_width | 0.691 | 0.703 | +0.011 | +2 |  |
| arm.extent | 0.861 | 0.861 | +0.000 | +0 |  |
| hand.outer_width | 0.770 | 0.789 | +0.019 | +3 |  |
| hand.solid_width | 0.696 | 0.712 | +0.016 | +2 |  |
| hand.extent | 0.882 | 0.881 | -0.001 | -0 |  |
| thigh.outer_width | 0.755 | 0.777 | +0.022 | +3 | y |
| thigh.solid_width | 0.627 | 0.627 | -0.000 | -0 |  |
| thigh.extent | 0.889 | 0.881 | -0.008 | -1 |  |
| shin.outer_width | 0.606 | 0.610 | +0.004 | +1 | y |
| shin.solid_width | 0.350 | 0.296 | -0.054 | -15 |  |
| shin.extent | 0.668 | 0.657 | -0.011 | -2 |  |
| foot.outer_width | 0.708 | 0.664 | -0.044 | -6 | y |
| foot.solid_width | 0.357 | 0.340 | -0.017 | -5 |  |
| foot.extent | 0.829 | 0.797 | -0.033 | -4 |  |
| total_height (highest point) | 2.400 | 2.400 | +0.000 | +0 | y |
| horn_B(image-left).tip_height | 2.400 | 2.400 | +0.000 | +0 | y |
| horn_B(image-left).span | 0.290 | 0.183 | -0.107 | -37 | y |
| horn_A(image-right).tip_height | 2.362 | 2.361 | -0.001 | -0 | y |
| horn_A(image-right).span | 0.103 | 0.055 | -0.048 | -46 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.363 | -0.031 | -8 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.750 | -0.022 | -3 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 0.881 | +0.022 | +3 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.194 | -0.009 | -4 |  |
| horns.solid_width | 0.113 | 0.105 | -0.008 | -7 |  |
| horns.extent | 0.473 | 0.366 | -0.107 | -23 |  |
| head.outer_width | 0.323 | 0.216 | -0.107 | -33 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.216 | -0.043 | -17 |  |
| head.solid_width | 0.291 | 0.216 | -0.075 | -26 |  |
| head.extent | 0.484 | 0.320 | -0.164 | -34 |  |
| snout.outer_width | 0.319 | 0.200 | -0.119 | -37 |  |
| snout.solid_width | 0.300 | 0.200 | -0.100 | -33 |  |
| snout.extent | 0.444 | 0.239 | -0.205 | -46 |  |
| neck.outer_width | 0.220 | 0.267 | +0.047 | +21 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.247 | +0.092 | +59 | y |
| neck.solid_width | 0.193 | 0.255 | +0.062 | +32 |  |
| neck.extent | 0.509 | 0.492 | -0.017 | -3 |  |
| neck_top.outer_width | 0.178 | 0.141 | -0.038 | -21 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.141 | +0.006 | +5 | y |
| neck_top.solid_width | 0.145 | 0.141 | -0.004 | -3 |  |
| neck_top.extent | 0.270 | 0.177 | -0.093 | -35 |  |
| neck_mid.outer_width | 0.133 | 0.211 | +0.078 | +59 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.145 | +0.011 | +9 | y |
| neck_mid.solid_width | 0.133 | 0.164 | +0.031 | +23 |  |
| neck_mid.extent | 0.139 | 0.336 | +0.197 | +142 |  |
| neck_base.outer_width | 0.366 | 0.461 | +0.094 | +26 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.461 | +0.247 | +115 | y |
| neck_base.solid_width | 0.335 | 0.461 | +0.125 | +37 |  |
| neck_base.extent | 0.389 | 0.492 | +0.104 | +27 |  |
| shoulders.outer_width | 0.585 | 0.623 | +0.038 | +7 | y |
| shoulders.solid_width | 0.585 | 0.623 | +0.038 | +7 |  |
| shoulders.extent | 0.668 | 0.633 | -0.036 | -5 |  |
| torso.outer_width | 0.783 | 0.683 | -0.100 | -13 | y |
| torso.solid_width | 0.733 | 0.680 | -0.053 | -7 |  |
| torso.extent | 1.103 | 0.807 | -0.296 | -27 |  |
| waist.outer_width | 0.897 | 0.747 | -0.151 | -17 | y |
| waist.solid_width | 0.827 | 0.747 | -0.080 | -10 |  |
| waist.extent | 0.928 | 0.751 | -0.178 | -19 |  |
| pelvis.outer_width | 0.966 | 0.775 | -0.192 | -20 | y |
| pelvis.solid_width | 0.921 | 0.761 | -0.160 | -17 |  |
| pelvis.extent | 1.053 | 0.807 | -0.247 | -23 |  |
| arm.outer_width | 0.839 | 0.723 | -0.116 | -14 |  |
| arm.solid_width | 0.790 | 0.703 | -0.087 | -11 |  |
| arm.extent | 1.103 | 0.861 | -0.242 | -22 |  |
| hand.outer_width | 0.908 | 0.789 | -0.119 | -13 |  |
| hand.solid_width | 0.879 | 0.712 | -0.166 | -19 |  |
| hand.extent | 1.111 | 0.882 | -0.230 | -21 |  |
| thigh.outer_width | 0.867 | 0.777 | -0.090 | -10 | y |
| thigh.solid_width | 0.862 | 0.627 | -0.235 | -27 |  |
| thigh.extent | 0.914 | 0.882 | -0.032 | -3 |  |
| shin.outer_width | 0.839 | 0.610 | -0.229 | -27 | y |
| shin.solid_width | 0.564 | 0.296 | -0.268 | -48 |  |
| shin.extent | 0.939 | 0.656 | -0.283 | -30 |  |
| foot.outer_width | 0.681 | 0.664 | -0.018 | -3 | y |
| foot.solid_width | 0.387 | 0.340 | -0.047 | -12 |  |
| foot.extent | 0.936 | 0.796 | -0.140 | -15 |  |
| total_height (highest point) | 2.400 | 2.400 | +0.000 | +0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. back neck_base.run_width (central run, fringe/skirt-free): ref 0.326 m, model 0.461 m, err +0.135 m (+41%)
2. back horn_B(image-left).span: ref 0.290 m, model 0.183 m, err -0.107 m (-37%)
3. back neck.run_width (central run, fringe/skirt-free): ref 0.178 m, model 0.247 m, err +0.069 m (+39%)
4. side torso.chest_to_back_depth: ref 0.513 m, model 0.460 m, err -0.053 m (-10%)
5. back horn_A(image-right).span: ref 0.103 m, model 0.055 m, err -0.048 m (-46%)
6. side neck_base.run_width (central run, fringe/skirt-free): ref 0.245 m, model 0.292 m, err +0.047 m (+19%)
7. side horn_B(front/long).span: ref 0.183 m, model 0.227 m, err +0.045 m (+25%)
8. back foot.outer_width: ref 0.708 m, model 0.664 m, err -0.044 m (-6%)
