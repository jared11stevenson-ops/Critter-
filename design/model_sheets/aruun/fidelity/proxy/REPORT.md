# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/proxy/proxy.glb`  forward +z  render height 2.400 m (top 2.400); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.862 | 0.860 | -0.003 | 1.03 | 0.103 | +0.000 |
| back | 0.855 | 0.855 | +0.000 | 0.98 | 0.072 | -0.002 |
| front (3/4 ref, qualitative) | 0.562 | 0.413 | +0.151 | 0.81 | 0.288 | -0.097 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.183 | -0.010 | -5 |  |
| horns.solid_width | 0.119 | 0.124 | +0.005 | +4 |  |
| horns.extent | 0.381 | 0.385 | +0.004 | +1 |  |
| head.outer_width | 0.226 | 0.245 | +0.018 | +8 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.241 | +0.041 | +21 |  |
| head.solid_width | 0.213 | 0.244 | +0.031 | +15 |  |
| head.extent | 0.307 | 0.303 | -0.004 | -1 |  |
| snout.outer_width | 0.236 | 0.251 | +0.015 | +6 |  |
| snout.solid_width | 0.218 | 0.251 | +0.033 | +15 |  |
| snout.extent | 0.307 | 0.303 | -0.004 | -1 |  |
| neck.outer_width | 0.150 | 0.173 | +0.023 | +15 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.173 | +0.025 | +17 | y |
| neck.solid_width | 0.149 | 0.173 | +0.024 | +16 |  |
| neck.extent | 0.314 | 0.324 | +0.010 | +3 |  |
| neck_top.outer_width | 0.108 | 0.109 | +0.001 | +1 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.109 | +0.001 | +1 | y |
| neck_top.solid_width | 0.108 | 0.109 | +0.001 | +1 |  |
| neck_top.extent | 0.110 | 0.117 | +0.007 | +6 |  |
| neck_mid.outer_width | 0.115 | 0.134 | +0.019 | +16 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.133 | +0.019 | +16 | y |
| neck_mid.solid_width | 0.115 | 0.134 | +0.019 | +16 |  |
| neck_mid.extent | 0.124 | 0.180 | +0.056 | +45 |  |
| neck_base.outer_width | 0.252 | 0.291 | +0.039 | +16 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.291 | +0.046 | +19 | y |
| neck_base.solid_width | 0.250 | 0.291 | +0.041 | +16 |  |
| neck_base.extent | 0.314 | 0.324 | +0.010 | +3 |  |
| shoulders.outer_width | 0.402 | 0.428 | +0.026 | +7 | y |
| shoulders.solid_width | 0.402 | 0.428 | +0.026 | +7 |  |
| shoulders.extent | 0.436 | 0.444 | +0.007 | +2 |  |
| torso.outer_width | 0.423 | 0.416 | -0.007 | -2 |  |
| torso.solid_width | 0.413 | 0.416 | +0.004 | +1 |  |
| torso.extent | 0.537 | 0.469 | -0.068 | -13 |  |
| waist.outer_width | 0.460 | 0.441 | -0.020 | -4 | y |
| waist.solid_width | 0.460 | 0.441 | -0.020 | -4 |  |
| waist.extent | 0.468 | 0.444 | -0.024 | -5 |  |
| pelvis.outer_width | 0.419 | 0.401 | -0.018 | -4 |  |
| pelvis.solid_width | 0.405 | 0.401 | -0.004 | -1 |  |
| pelvis.extent | 0.446 | 0.433 | -0.013 | -3 |  |
| arm.outer_width | 0.399 | 0.388 | -0.011 | -3 |  |
| arm.solid_width | 0.387 | 0.388 | +0.001 | +0 |  |
| arm.extent | 0.537 | 0.469 | -0.068 | -13 |  |
| hand.outer_width | 0.302 | 0.297 | -0.005 | -2 |  |
| hand.solid_width | 0.294 | 0.297 | +0.003 | +1 |  |
| hand.extent | 0.463 | 0.452 | -0.011 | -2 |  |
| thigh.outer_width | 0.192 | 0.198 | +0.006 | +3 |  |
| thigh.solid_width | 0.187 | 0.197 | +0.010 | +5 |  |
| thigh.extent | 0.360 | 0.354 | -0.006 | -2 |  |
| shin.outer_width | 0.117 | 0.121 | +0.004 | +3 | y |
| shin.solid_width | 0.117 | 0.121 | +0.004 | +3 |  |
| shin.extent | 0.198 | 0.204 | +0.006 | +3 |  |
| foot.outer_width | 0.235 | 0.232 | -0.003 | -1 | y |
| foot.solid_width | 0.229 | 0.232 | +0.003 | +1 |  |
| foot.extent | 0.416 | 0.410 | -0.006 | -1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.127 | -0.004 | -3 | y |
| head.length (nape..snout tip) | 0.307 | 0.303 | -0.004 | -1 | y |
| foot.length (heel..toe) | 0.416 | 0.410 | -0.006 | -1 | y |
| torso.chest_to_back_depth | 0.513 | 0.460 | -0.053 | -10 | y |
| head.snout_tip_height | 2.008 | 2.011 | +0.004 | +0 |  |
| total_height (highest point) | 2.400 | 2.400 | +0.000 | +0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.361 | -0.039 | -2 | y |
| horn_A(rear/thick).span | 0.217 | 0.199 | -0.018 | -8 | y |
| horn_B(front/long).tip_height | 2.391 | 2.400 | +0.009 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.237 | +0.054 | +30 | y |
| horns.total_depth_spread (side) | 0.334 | 0.361 | +0.027 | +8 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.193 | +0.003 | +1 |  |
| horns.solid_width | 0.119 | 0.104 | -0.015 | -13 |  |
| horns.extent | 0.439 | 0.367 | -0.072 | -16 |  |
| head.outer_width | 0.210 | 0.216 | +0.006 | +3 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.215 | +0.011 | +6 |  |
| head.solid_width | 0.207 | 0.216 | +0.008 | +4 |  |
| head.extent | 0.331 | 0.320 | -0.010 | -3 |  |
| snout.outer_width | 0.195 | 0.200 | +0.005 | +3 |  |
| snout.solid_width | 0.194 | 0.200 | +0.006 | +3 |  |
| snout.extent | 0.258 | 0.239 | -0.018 | -7 |  |
| neck.outer_width | 0.198 | 0.223 | +0.025 | +13 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.221 | +0.043 | +24 | y |
| neck.solid_width | 0.191 | 0.222 | +0.032 | +17 |  |
| neck.extent | 0.458 | 0.422 | -0.036 | -8 |  |
| neck_top.outer_width | 0.142 | 0.137 | -0.005 | -4 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.138 | +0.004 | +3 | y |
| neck_top.solid_width | 0.138 | 0.137 | -0.000 | -0 |  |
| neck_top.extent | 0.224 | 0.179 | -0.045 | -20 |  |
| neck_mid.outer_width | 0.122 | 0.154 | +0.032 | +26 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.153 | +0.031 | +25 | y |
| neck_mid.solid_width | 0.122 | 0.154 | +0.032 | +26 |  |
| neck_mid.extent | 0.133 | 0.253 | +0.120 | +90 |  |
| neck_base.outer_width | 0.345 | 0.387 | +0.042 | +12 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.387 | +0.061 | +19 | y |
| neck_base.solid_width | 0.344 | 0.387 | +0.043 | +13 |  |
| neck_base.extent | 0.409 | 0.420 | +0.012 | +3 |  |
| shoulders.outer_width | 0.625 | 0.620 | -0.004 | -1 | y |
| shoulders.solid_width | 0.625 | 0.620 | -0.004 | -1 |  |
| shoulders.extent | 0.639 | 0.633 | -0.006 | -1 |  |
| torso.outer_width | 0.675 | 0.677 | +0.002 | +0 | y |
| torso.solid_width | 0.666 | 0.674 | +0.008 | +1 |  |
| torso.extent | 0.812 | 0.806 | -0.006 | -1 |  |
| waist.outer_width | 0.743 | 0.746 | +0.003 | +0 | y |
| waist.solid_width | 0.742 | 0.746 | +0.004 | +0 |  |
| waist.extent | 0.751 | 0.750 | -0.001 | -0 |  |
| pelvis.outer_width | 0.784 | 0.772 | -0.012 | -2 | y |
| pelvis.solid_width | 0.745 | 0.757 | +0.013 | +2 |  |
| pelvis.extent | 0.812 | 0.806 | -0.006 | -1 |  |
| arm.outer_width | 0.712 | 0.721 | +0.009 | +1 |  |
| arm.solid_width | 0.691 | 0.693 | +0.001 | +0 |  |
| arm.extent | 0.861 | 0.861 | +0.000 | +0 |  |
| hand.outer_width | 0.770 | 0.789 | +0.019 | +2 |  |
| hand.solid_width | 0.696 | 0.691 | -0.005 | -1 |  |
| hand.extent | 0.882 | 0.881 | -0.001 | -0 |  |
| thigh.outer_width | 0.755 | 0.776 | +0.021 | +3 | y |
| thigh.solid_width | 0.627 | 0.602 | -0.025 | -4 |  |
| thigh.extent | 0.889 | 0.881 | -0.008 | -1 |  |
| shin.outer_width | 0.606 | 0.610 | +0.004 | +1 | y |
| shin.solid_width | 0.350 | 0.296 | -0.054 | -15 |  |
| shin.extent | 0.668 | 0.657 | -0.011 | -2 |  |
| foot.outer_width | 0.708 | 0.631 | -0.077 | -11 | y |
| foot.solid_width | 0.357 | 0.320 | -0.037 | -10 |  |
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
| horns.outer_width | 0.202 | 0.193 | -0.009 | -4 |  |
| horns.solid_width | 0.113 | 0.104 | -0.009 | -8 |  |
| horns.extent | 0.473 | 0.366 | -0.107 | -23 |  |
| head.outer_width | 0.323 | 0.216 | -0.108 | -33 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.214 | -0.045 | -18 |  |
| head.solid_width | 0.291 | 0.216 | -0.076 | -26 |  |
| head.extent | 0.484 | 0.320 | -0.164 | -34 |  |
| snout.outer_width | 0.319 | 0.200 | -0.119 | -37 |  |
| snout.solid_width | 0.300 | 0.200 | -0.100 | -33 |  |
| snout.extent | 0.444 | 0.239 | -0.205 | -46 |  |
| neck.outer_width | 0.220 | 0.223 | +0.002 | +1 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.221 | +0.066 | +43 | y |
| neck.solid_width | 0.193 | 0.222 | +0.029 | +15 |  |
| neck.extent | 0.509 | 0.422 | -0.087 | -17 |  |
| neck_top.outer_width | 0.178 | 0.137 | -0.041 | -23 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.138 | +0.003 | +2 | y |
| neck_top.solid_width | 0.145 | 0.137 | -0.008 | -5 |  |
| neck_top.extent | 0.270 | 0.179 | -0.092 | -34 |  |
| neck_mid.outer_width | 0.133 | 0.154 | +0.021 | +16 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.153 | +0.020 | +15 | y |
| neck_mid.solid_width | 0.133 | 0.154 | +0.021 | +16 |  |
| neck_mid.extent | 0.139 | 0.254 | +0.115 | +83 |  |
| neck_base.outer_width | 0.366 | 0.387 | +0.021 | +6 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.387 | +0.173 | +81 | y |
| neck_base.solid_width | 0.335 | 0.387 | +0.052 | +15 |  |
| neck_base.extent | 0.389 | 0.420 | +0.031 | +8 |  |
| shoulders.outer_width | 0.585 | 0.621 | +0.036 | +6 | y |
| shoulders.solid_width | 0.585 | 0.621 | +0.036 | +6 |  |
| shoulders.extent | 0.668 | 0.633 | -0.036 | -5 |  |
| torso.outer_width | 0.783 | 0.677 | -0.105 | -13 | y |
| torso.solid_width | 0.733 | 0.674 | -0.059 | -8 |  |
| torso.extent | 1.103 | 0.807 | -0.296 | -27 |  |
| waist.outer_width | 0.897 | 0.746 | -0.151 | -17 | y |
| waist.solid_width | 0.827 | 0.746 | -0.081 | -10 |  |
| waist.extent | 0.928 | 0.750 | -0.178 | -19 |  |
| pelvis.outer_width | 0.966 | 0.772 | -0.194 | -20 | y |
| pelvis.solid_width | 0.921 | 0.757 | -0.164 | -18 |  |
| pelvis.extent | 1.053 | 0.807 | -0.247 | -23 |  |
| arm.outer_width | 0.839 | 0.721 | -0.118 | -14 |  |
| arm.solid_width | 0.790 | 0.693 | -0.097 | -12 |  |
| arm.extent | 1.103 | 0.861 | -0.242 | -22 |  |
| hand.outer_width | 0.908 | 0.789 | -0.120 | -13 |  |
| hand.solid_width | 0.879 | 0.691 | -0.188 | -21 |  |
| hand.extent | 1.111 | 0.882 | -0.230 | -21 |  |
| thigh.outer_width | 0.867 | 0.776 | -0.091 | -10 | y |
| thigh.solid_width | 0.862 | 0.602 | -0.260 | -30 |  |
| thigh.extent | 0.914 | 0.882 | -0.032 | -3 |  |
| shin.outer_width | 0.839 | 0.610 | -0.229 | -27 | y |
| shin.solid_width | 0.564 | 0.296 | -0.268 | -48 |  |
| shin.extent | 0.939 | 0.656 | -0.283 | -30 |  |
| foot.outer_width | 0.681 | 0.631 | -0.051 | -7 | y |
| foot.solid_width | 0.387 | 0.320 | -0.066 | -17 |  |
| foot.extent | 0.936 | 0.796 | -0.140 | -15 |  |
| total_height (highest point) | 2.400 | 2.400 | +0.000 | +0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. back horn_B(image-left).span: ref 0.290 m, model 0.183 m, err -0.107 m (-37%)
2. back foot.outer_width: ref 0.708 m, model 0.631 m, err -0.077 m (-11%)
3. back neck_base.run_width (central run, fringe/skirt-free): ref 0.326 m, model 0.387 m, err +0.061 m (+19%)
4. side horn_B(front/long).span: ref 0.183 m, model 0.237 m, err +0.054 m (+30%)
5. side torso.chest_to_back_depth: ref 0.513 m, model 0.460 m, err -0.053 m (-10%)
6. back horn_A(image-right).span: ref 0.103 m, model 0.055 m, err -0.048 m (-46%)
7. side neck_base.run_width (central run, fringe/skirt-free): ref 0.245 m, model 0.291 m, err +0.046 m (+19%)
8. back neck.run_width (central run, fringe/skirt-free): ref 0.178 m, model 0.221 m, err +0.043 m (+24%)
