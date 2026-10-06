# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/proxy/proxy.glb`  forward +z  render height 2.403 m (top 2.403); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.874 | 0.873 | -0.002 | 1.05 | 0.081 | +0.005 |
| back | 0.881 | 0.881 | -0.001 | 1.02 | 0.077 | +0.008 |
| front (3/4 ref, qualitative) | 0.583 | 0.427 | +0.156 | 0.85 | 0.305 | -0.088 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.192 | -0.001 | -1 |  |
| horns.solid_width | 0.119 | 0.133 | +0.014 | +12 |  |
| horns.extent | 0.381 | 0.385 | +0.004 | +1 |  |
| head.outer_width | 0.226 | 0.245 | +0.018 | +8 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.241 | +0.041 | +21 |  |
| head.solid_width | 0.213 | 0.244 | +0.031 | +15 |  |
| head.extent | 0.307 | 0.303 | -0.004 | -1 |  |
| snout.outer_width | 0.236 | 0.251 | +0.015 | +6 |  |
| snout.solid_width | 0.218 | 0.251 | +0.033 | +15 |  |
| snout.extent | 0.307 | 0.303 | -0.004 | -1 |  |
| neck.outer_width | 0.150 | 0.166 | +0.016 | +11 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.165 | +0.018 | +12 | y |
| neck.solid_width | 0.149 | 0.166 | +0.017 | +11 |  |
| neck.extent | 0.314 | 0.314 | +0.001 | +0 |  |
| neck_top.outer_width | 0.108 | 0.111 | +0.002 | +2 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.111 | +0.002 | +2 | y |
| neck_top.solid_width | 0.108 | 0.111 | +0.002 | +2 |  |
| neck_top.extent | 0.110 | 0.117 | +0.007 | +7 |  |
| neck_mid.outer_width | 0.115 | 0.123 | +0.008 | +7 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.123 | +0.008 | +7 | y |
| neck_mid.solid_width | 0.115 | 0.123 | +0.008 | +7 |  |
| neck_mid.extent | 0.124 | 0.168 | +0.044 | +36 |  |
| neck_base.outer_width | 0.252 | 0.282 | +0.031 | +12 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.280 | +0.034 | +14 | y |
| neck_base.solid_width | 0.250 | 0.281 | +0.031 | +12 |  |
| neck_base.extent | 0.314 | 0.314 | +0.001 | +0 |  |
| shoulders.outer_width | 0.402 | 0.427 | +0.025 | +6 | y |
| shoulders.solid_width | 0.402 | 0.427 | +0.025 | +6 |  |
| shoulders.extent | 0.436 | 0.443 | +0.007 | +2 |  |
| torso.outer_width | 0.423 | 0.421 | -0.003 | -1 |  |
| torso.solid_width | 0.413 | 0.421 | +0.008 | +2 |  |
| torso.extent | 0.537 | 0.476 | -0.060 | -11 |  |
| waist.outer_width | 0.460 | 0.447 | -0.013 | -3 | y |
| waist.solid_width | 0.460 | 0.447 | -0.013 | -3 |  |
| waist.extent | 0.468 | 0.454 | -0.014 | -3 |  |
| pelvis.outer_width | 0.419 | 0.409 | -0.010 | -2 |  |
| pelvis.solid_width | 0.405 | 0.409 | +0.004 | +1 |  |
| pelvis.extent | 0.446 | 0.440 | -0.006 | -1 |  |
| arm.outer_width | 0.399 | 0.393 | -0.006 | -2 |  |
| arm.solid_width | 0.387 | 0.392 | +0.006 | +1 |  |
| arm.extent | 0.537 | 0.476 | -0.060 | -11 |  |
| hand.outer_width | 0.302 | 0.302 | -0.000 | -0 |  |
| hand.solid_width | 0.294 | 0.301 | +0.007 | +2 |  |
| hand.extent | 0.463 | 0.459 | -0.004 | -1 |  |
| thigh.outer_width | 0.192 | 0.200 | +0.008 | +4 |  |
| thigh.solid_width | 0.187 | 0.199 | +0.011 | +6 |  |
| thigh.extent | 0.360 | 0.369 | +0.009 | +3 |  |
| shin.outer_width | 0.117 | 0.122 | +0.004 | +4 | y |
| shin.solid_width | 0.117 | 0.122 | +0.004 | +4 |  |
| shin.extent | 0.198 | 0.206 | +0.008 | +4 |  |
| foot.outer_width | 0.235 | 0.250 | +0.015 | +6 | y |
| foot.solid_width | 0.229 | 0.250 | +0.021 | +9 |  |
| foot.extent | 0.416 | 0.410 | -0.006 | -1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.127 | -0.003 | -2 | y |
| head.length (nape..snout tip) | 0.307 | 0.303 | -0.004 | -1 | y |
| foot.length (heel..toe) | 0.416 | 0.410 | -0.006 | -1 | y |
| torso.chest_to_back_depth | 0.513 | 0.460 | -0.053 | -10 | y |
| head.snout_tip_height | 2.008 | 2.011 | +0.004 | +0 |  |
| total_height (highest point) | 2.400 | 2.402 | +0.002 | +0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.367 | -0.033 | -1 | y |
| horn_A(rear/thick).span | 0.217 | 0.198 | -0.019 | -9 | y |
| horn_B(front/long).tip_height | 2.391 | 2.400 | +0.009 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.237 | +0.054 | +30 | y |
| horns.total_depth_spread (side) | 0.334 | 0.361 | +0.027 | +8 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.221 | +0.031 | +16 |  |
| horns.solid_width | 0.119 | 0.131 | +0.012 | +10 |  |
| horns.extent | 0.439 | 0.367 | -0.072 | -16 |  |
| head.outer_width | 0.210 | 0.216 | +0.006 | +3 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.215 | +0.011 | +6 |  |
| head.solid_width | 0.207 | 0.215 | +0.008 | +4 |  |
| head.extent | 0.331 | 0.320 | -0.010 | -3 |  |
| snout.outer_width | 0.195 | 0.200 | +0.005 | +3 |  |
| snout.solid_width | 0.194 | 0.200 | +0.006 | +3 |  |
| snout.extent | 0.258 | 0.239 | -0.018 | -7 |  |
| neck.outer_width | 0.198 | 0.203 | +0.005 | +3 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.202 | +0.024 | +14 | y |
| neck.solid_width | 0.191 | 0.203 | +0.012 | +6 |  |
| neck.extent | 0.458 | 0.406 | -0.052 | -11 |  |
| neck_top.outer_width | 0.142 | 0.136 | -0.006 | -4 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.137 | +0.003 | +2 | y |
| neck_top.solid_width | 0.138 | 0.136 | -0.001 | -1 |  |
| neck_top.extent | 0.224 | 0.179 | -0.045 | -20 |  |
| neck_mid.outer_width | 0.122 | 0.144 | +0.022 | +18 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.142 | +0.020 | +16 | y |
| neck_mid.solid_width | 0.122 | 0.144 | +0.022 | +18 |  |
| neck_mid.extent | 0.133 | 0.240 | +0.106 | +80 |  |
| neck_base.outer_width | 0.345 | 0.342 | -0.003 | -1 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.340 | +0.015 | +4 | y |
| neck_base.solid_width | 0.344 | 0.342 | -0.002 | -1 |  |
| neck_base.extent | 0.409 | 0.381 | -0.028 | -7 |  |
| shoulders.outer_width | 0.625 | 0.617 | -0.007 | -1 | y |
| shoulders.solid_width | 0.625 | 0.617 | -0.007 | -1 |  |
| shoulders.extent | 0.639 | 0.632 | -0.007 | -1 |  |
| torso.outer_width | 0.675 | 0.673 | -0.002 | -0 | y |
| torso.solid_width | 0.666 | 0.670 | +0.004 | +1 |  |
| torso.extent | 0.812 | 0.806 | -0.006 | -1 |  |
| waist.outer_width | 0.743 | 0.746 | +0.003 | +0 | y |
| waist.solid_width | 0.742 | 0.746 | +0.004 | +0 |  |
| waist.extent | 0.751 | 0.750 | -0.001 | -0 |  |
| pelvis.outer_width | 0.784 | 0.772 | -0.012 | -2 | y |
| pelvis.solid_width | 0.745 | 0.756 | +0.012 | +2 |  |
| pelvis.extent | 0.812 | 0.806 | -0.006 | -1 |  |
| arm.outer_width | 0.712 | 0.722 | +0.009 | +1 |  |
| arm.solid_width | 0.691 | 0.706 | +0.015 | +2 |  |
| arm.extent | 0.861 | 0.861 | +0.000 | +0 |  |
| hand.outer_width | 0.770 | 0.787 | +0.017 | +2 |  |
| hand.solid_width | 0.696 | 0.734 | +0.038 | +5 |  |
| hand.extent | 0.882 | 0.881 | -0.001 | -0 |  |
| thigh.outer_width | 0.755 | 0.771 | +0.016 | +2 | y |
| thigh.solid_width | 0.627 | 0.665 | +0.038 | +6 |  |
| thigh.extent | 0.889 | 0.881 | -0.008 | -1 |  |
| shin.outer_width | 0.606 | 0.603 | -0.003 | -1 | y |
| shin.solid_width | 0.350 | 0.329 | -0.021 | -6 |  |
| shin.extent | 0.668 | 0.668 | +0.001 | +0 |  |
| foot.outer_width | 0.708 | 0.737 | +0.029 | +4 | y |
| foot.solid_width | 0.357 | 0.393 | +0.036 | +10 |  |
| foot.extent | 0.829 | 0.797 | -0.033 | -4 |  |
| total_height (highest point) | 2.400 | 2.402 | +0.002 | +0 | y |
| horn_B(image-left).tip_height | 2.400 | 2.400 | +0.000 | +0 | y |
| horn_B(image-left).span | 0.290 | 0.250 | -0.041 | -14 | y |
| horn_A(image-right).tip_height | 2.362 | 2.393 | +0.031 | +1 | y |
| horn_A(image-right).span | 0.103 | 0.113 | +0.010 | +10 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.363 | -0.031 | -8 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.750 | -0.022 | -3 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 0.881 | +0.022 | +3 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.221 | +0.019 | +9 |  |
| horns.solid_width | 0.113 | 0.131 | +0.018 | +16 |  |
| horns.extent | 0.473 | 0.366 | -0.107 | -23 |  |
| head.outer_width | 0.323 | 0.216 | -0.108 | -33 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.213 | -0.045 | -18 |  |
| head.solid_width | 0.291 | 0.216 | -0.076 | -26 |  |
| head.extent | 0.484 | 0.320 | -0.164 | -34 |  |
| snout.outer_width | 0.319 | 0.200 | -0.119 | -37 |  |
| snout.solid_width | 0.300 | 0.200 | -0.100 | -33 |  |
| snout.extent | 0.444 | 0.239 | -0.205 | -46 |  |
| neck.outer_width | 0.220 | 0.203 | -0.017 | -8 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.202 | +0.047 | +30 | y |
| neck.solid_width | 0.193 | 0.203 | +0.010 | +5 |  |
| neck.extent | 0.509 | 0.407 | -0.102 | -20 |  |
| neck_top.outer_width | 0.178 | 0.136 | -0.042 | -24 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.137 | +0.002 | +2 | y |
| neck_top.solid_width | 0.145 | 0.136 | -0.009 | -6 |  |
| neck_top.extent | 0.270 | 0.179 | -0.092 | -34 |  |
| neck_mid.outer_width | 0.133 | 0.144 | +0.011 | +8 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.142 | +0.009 | +7 | y |
| neck_mid.solid_width | 0.133 | 0.144 | +0.011 | +8 |  |
| neck_mid.extent | 0.139 | 0.239 | +0.100 | +72 |  |
| neck_base.outer_width | 0.366 | 0.342 | -0.024 | -7 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.340 | +0.127 | +59 | y |
| neck_base.solid_width | 0.335 | 0.342 | +0.006 | +2 |  |
| neck_base.extent | 0.389 | 0.381 | -0.008 | -2 |  |
| shoulders.outer_width | 0.585 | 0.617 | +0.033 | +6 | y |
| shoulders.solid_width | 0.585 | 0.617 | +0.033 | +6 |  |
| shoulders.extent | 0.668 | 0.632 | -0.036 | -5 |  |
| torso.outer_width | 0.783 | 0.673 | -0.110 | -14 | y |
| torso.solid_width | 0.733 | 0.670 | -0.063 | -9 |  |
| torso.extent | 1.103 | 0.807 | -0.296 | -27 |  |
| waist.outer_width | 0.897 | 0.746 | -0.151 | -17 | y |
| waist.solid_width | 0.827 | 0.746 | -0.081 | -10 |  |
| waist.extent | 0.928 | 0.750 | -0.178 | -19 |  |
| pelvis.outer_width | 0.966 | 0.772 | -0.194 | -20 | y |
| pelvis.solid_width | 0.921 | 0.756 | -0.165 | -18 |  |
| pelvis.extent | 1.053 | 0.807 | -0.247 | -23 |  |
| arm.outer_width | 0.839 | 0.722 | -0.118 | -14 |  |
| arm.solid_width | 0.790 | 0.706 | -0.083 | -11 |  |
| arm.extent | 1.103 | 0.861 | -0.242 | -22 |  |
| hand.outer_width | 0.908 | 0.787 | -0.121 | -13 |  |
| hand.solid_width | 0.879 | 0.734 | -0.145 | -16 |  |
| hand.extent | 1.111 | 0.882 | -0.230 | -21 |  |
| thigh.outer_width | 0.867 | 0.771 | -0.096 | -11 | y |
| thigh.solid_width | 0.862 | 0.665 | -0.197 | -23 |  |
| thigh.extent | 0.914 | 0.882 | -0.032 | -3 |  |
| shin.outer_width | 0.839 | 0.603 | -0.236 | -28 | y |
| shin.solid_width | 0.564 | 0.329 | -0.235 | -42 |  |
| shin.extent | 0.939 | 0.668 | -0.271 | -29 |  |
| foot.outer_width | 0.681 | 0.737 | +0.055 | +8 | y |
| foot.solid_width | 0.387 | 0.393 | +0.006 | +2 |  |
| foot.extent | 0.936 | 0.796 | -0.140 | -15 |  |
| total_height (highest point) | 2.400 | 2.402 | +0.002 | +0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. side horn_B(front/long).span: ref 0.183 m, model 0.237 m, err +0.054 m (+30%)
2. side torso.chest_to_back_depth: ref 0.513 m, model 0.460 m, err -0.053 m (-10%)
3. back horn_B(image-left).span: ref 0.290 m, model 0.250 m, err -0.041 m (-14%)
4. side neck_base.run_width (central run, fringe/skirt-free): ref 0.245 m, model 0.280 m, err +0.034 m (+14%)
5. side horn_A(rear/thick).tip_height: ref 2.400 m, model 2.367 m, err -0.033 m (-1%)
6. back horn_A(image-right).tip_height: ref 2.362 m, model 2.393 m, err +0.031 m (+1%)
7. back horns.total_spread (back, outer tip to outer tip): ref 0.393 m, model 0.363 m, err -0.031 m (-8%)
8. back foot.outer_width: ref 0.708 m, model 0.737 m, err +0.029 m (+4%)
