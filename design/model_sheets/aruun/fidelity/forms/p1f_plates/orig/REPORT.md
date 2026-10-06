# Fidelity comparison (model - reference)

model: `design/model_sheets/aruun/fidelity/forms/p1f_plates/forms.glb`  forward +z  render height 2.394 m (top 2.394); mace islands dropped: 0 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.898 | 0.895 | -0.002 | 1.05 | 0.078 | +0.009 |
| back | 0.893 | 0.893 | +0.001 | 1.02 | 0.060 | +0.012 |
| front (3/4 ref, qualitative) | 0.585 | 0.428 | +0.160 | 0.84 | 0.293 | -0.084 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.196 | +0.003 | +2 |  |
| horns.solid_width | 0.119 | 0.120 | +0.000 | +0 |  |
| horns.extent | 0.381 | 0.405 | +0.024 | +6 |  |
| head.outer_width | 0.226 | 0.229 | +0.002 | +1 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.210 | +0.009 | +5 |  |
| head.solid_width | 0.213 | 0.220 | +0.007 | +3 |  |
| head.extent | 0.307 | 0.298 | -0.009 | -3 |  |
| snout.outer_width | 0.236 | 0.236 | -0.000 | -0 |  |
| snout.solid_width | 0.218 | 0.225 | +0.006 | +3 |  |
| snout.extent | 0.307 | 0.298 | -0.009 | -3 |  |
| neck.outer_width | 0.150 | 0.159 | +0.008 | +6 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.157 | +0.010 | +7 | y |
| neck.solid_width | 0.149 | 0.158 | +0.009 | +6 |  |
| neck.extent | 0.314 | 0.288 | -0.026 | -8 |  |
| neck_top.outer_width | 0.108 | 0.116 | +0.008 | +7 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.116 | +0.008 | +7 | y |
| neck_top.solid_width | 0.108 | 0.116 | +0.008 | +7 |  |
| neck_top.extent | 0.110 | 0.125 | +0.015 | +14 |  |
| neck_mid.outer_width | 0.115 | 0.129 | +0.014 | +13 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.129 | +0.014 | +13 | y |
| neck_mid.solid_width | 0.115 | 0.129 | +0.014 | +13 |  |
| neck_mid.extent | 0.124 | 0.160 | +0.036 | +29 |  |
| neck_base.outer_width | 0.252 | 0.248 | -0.004 | -2 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.245 | -0.000 | -0 | y |
| neck_base.solid_width | 0.250 | 0.246 | -0.004 | -1 |  |
| neck_base.extent | 0.314 | 0.288 | -0.026 | -8 |  |
| shoulders.outer_width | 0.402 | 0.418 | +0.016 | +4 | y |
| shoulders.solid_width | 0.402 | 0.418 | +0.016 | +4 |  |
| shoulders.extent | 0.436 | 0.443 | +0.006 | +1 |  |
| torso.outer_width | 0.423 | 0.428 | +0.005 | +1 |  |
| torso.solid_width | 0.413 | 0.424 | +0.011 | +3 |  |
| torso.extent | 0.537 | 0.524 | -0.013 | -2 |  |
| waist.outer_width | 0.460 | 0.455 | -0.005 | -1 | y |
| waist.solid_width | 0.460 | 0.455 | -0.005 | -1 |  |
| waist.extent | 0.468 | 0.465 | -0.002 | -1 |  |
| pelvis.outer_width | 0.419 | 0.408 | -0.012 | -3 |  |
| pelvis.solid_width | 0.405 | 0.408 | +0.003 | +1 |  |
| pelvis.extent | 0.446 | 0.440 | -0.006 | -1 |  |
| arm.outer_width | 0.399 | 0.407 | +0.008 | +2 |  |
| arm.solid_width | 0.387 | 0.402 | +0.015 | +4 |  |
| arm.extent | 0.537 | 0.524 | -0.013 | -2 |  |
| hand.outer_width | 0.302 | 0.306 | +0.004 | +1 |  |
| hand.solid_width | 0.294 | 0.303 | +0.009 | +3 |  |
| hand.extent | 0.463 | 0.460 | -0.003 | -1 |  |
| thigh.outer_width | 0.192 | 0.208 | +0.016 | +9 |  |
| thigh.solid_width | 0.187 | 0.204 | +0.017 | +9 |  |
| thigh.extent | 0.360 | 0.378 | +0.018 | +5 |  |
| shin.outer_width | 0.117 | 0.129 | +0.012 | +10 | y |
| shin.solid_width | 0.117 | 0.129 | +0.012 | +10 |  |
| shin.extent | 0.198 | 0.208 | +0.010 | +5 |  |
| foot.outer_width | 0.235 | 0.252 | +0.017 | +7 | y |
| foot.solid_width | 0.229 | 0.251 | +0.022 | +10 |  |
| foot.extent | 0.416 | 0.419 | +0.003 | +1 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.124 | -0.006 | -5 | y |
| head.length (nape..snout tip) | 0.307 | 0.298 | -0.009 | -3 | y |
| foot.length (heel..toe) | 0.416 | 0.419 | +0.003 | +1 | y |
| torso.chest_to_back_depth | 0.513 | 0.508 | -0.006 | -1 | y |
| head.snout_tip_height | 2.008 | 2.005 | -0.002 | -0 |  |
| total_height (highest point) | 2.400 | 2.394 | -0.006 | -0 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.386 | -0.014 | -1 | y |
| horn_A(rear/thick).span | 0.217 | 0.237 | +0.020 | +9 | y |
| horn_B(front/long).tip_height | 2.391 | 2.394 | +0.003 | +0 | y |
| horn_B(front/long).span | 0.183 | 0.203 | +0.021 | +11 | y |
| horns.total_depth_spread (side) | 0.334 | 0.355 | +0.020 | +6 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.224 | +0.033 | +17 |  |
| horns.solid_width | 0.119 | 0.121 | +0.002 | +1 |  |
| horns.extent | 0.439 | 0.456 | +0.017 | +4 |  |
| head.outer_width | 0.210 | 0.217 | +0.008 | +4 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.218 | +0.014 | +7 |  |
| head.solid_width | 0.207 | 0.217 | +0.010 | +5 |  |
| head.extent | 0.331 | 0.326 | -0.004 | -1 |  |
| snout.outer_width | 0.195 | 0.197 | +0.003 | +1 |  |
| snout.solid_width | 0.194 | 0.197 | +0.004 | +2 |  |
| snout.extent | 0.258 | 0.213 | -0.045 | -17 |  |
| neck.outer_width | 0.198 | 0.190 | -0.008 | -4 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.190 | +0.012 | +7 | y |
| neck.solid_width | 0.191 | 0.190 | -0.001 | -0 |  |
| neck.extent | 0.458 | 0.444 | -0.014 | -3 |  |
| neck_top.outer_width | 0.142 | 0.136 | -0.006 | -4 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.137 | +0.003 | +2 | y |
| neck_top.solid_width | 0.138 | 0.136 | -0.001 | -1 |  |
| neck_top.extent | 0.224 | 0.194 | -0.030 | -13 |  |
| neck_mid.outer_width | 0.122 | 0.121 | -0.002 | -1 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.121 | -0.002 | -1 | y |
| neck_mid.solid_width | 0.122 | 0.121 | -0.002 | -1 |  |
| neck_mid.extent | 0.133 | 0.150 | +0.017 | +12 |  |
| neck_base.outer_width | 0.345 | 0.334 | -0.011 | -3 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.334 | +0.008 | +2 | y |
| neck_base.solid_width | 0.344 | 0.334 | -0.010 | -3 |  |
| neck_base.extent | 0.409 | 0.398 | -0.011 | -3 |  |
| shoulders.outer_width | 0.625 | 0.628 | +0.004 | +1 | y |
| shoulders.solid_width | 0.625 | 0.628 | +0.004 | +1 |  |
| shoulders.extent | 0.639 | 0.644 | +0.006 | +1 |  |
| torso.outer_width | 0.675 | 0.684 | +0.009 | +1 | y |
| torso.solid_width | 0.666 | 0.682 | +0.016 | +2 |  |
| torso.extent | 0.812 | 0.810 | -0.002 | -0 |  |
| waist.outer_width | 0.743 | 0.746 | +0.004 | +1 | y |
| waist.solid_width | 0.742 | 0.746 | +0.004 | +1 |  |
| waist.extent | 0.751 | 0.754 | +0.002 | +0 |  |
| pelvis.outer_width | 0.784 | 0.776 | -0.008 | -1 | y |
| pelvis.solid_width | 0.745 | 0.763 | +0.018 | +2 |  |
| pelvis.extent | 0.812 | 0.810 | -0.002 | -0 |  |
| arm.outer_width | 0.712 | 0.723 | +0.011 | +2 |  |
| arm.solid_width | 0.691 | 0.703 | +0.012 | +2 |  |
| arm.extent | 0.861 | 0.859 | -0.001 | -0 |  |
| hand.outer_width | 0.770 | 0.771 | +0.001 | +0 |  |
| hand.solid_width | 0.696 | 0.699 | +0.003 | +0 |  |
| hand.extent | 0.882 | 0.876 | -0.006 | -1 |  |
| thigh.outer_width | 0.755 | 0.757 | +0.002 | +0 | y |
| thigh.solid_width | 0.627 | 0.619 | -0.008 | -1 |  |
| thigh.extent | 0.889 | 0.874 | -0.015 | -2 |  |
| shin.outer_width | 0.606 | 0.621 | +0.015 | +2 | y |
| shin.solid_width | 0.350 | 0.354 | +0.005 | +1 |  |
| shin.extent | 0.668 | 0.682 | +0.014 | +2 |  |
| foot.outer_width | 0.708 | 0.730 | +0.022 | +3 | y |
| foot.solid_width | 0.357 | 0.366 | +0.010 | +3 |  |
| foot.extent | 0.829 | 0.776 | -0.053 | -6 |  |
| total_height (highest point) | 2.400 | 2.394 | -0.006 | -0 | y |
| horn_B(image-left).tip_height | 2.400 | 2.394 | -0.006 | -0 | y |
| horn_B(image-left).span | 0.290 | 0.304 | +0.014 | +5 | y |
| horn_A(image-right).tip_height | 2.362 | 2.386 | +0.024 | +1 | y |
| horn_A(image-right).span | 0.103 | 0.109 | +0.006 | +5 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.413 | +0.020 | +5 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.772 | +0.000 | +0 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 0.859 | +0.000 | +0 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.224 | +0.022 | +11 |  |
| horns.solid_width | 0.113 | 0.121 | +0.008 | +7 |  |
| horns.extent | 0.473 | 0.456 | -0.018 | -4 |  |
| head.outer_width | 0.323 | 0.217 | -0.106 | -33 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.218 | -0.041 | -16 |  |
| head.solid_width | 0.291 | 0.217 | -0.074 | -25 |  |
| head.extent | 0.484 | 0.327 | -0.157 | -32 |  |
| snout.outer_width | 0.319 | 0.197 | -0.122 | -38 |  |
| snout.solid_width | 0.300 | 0.197 | -0.103 | -34 |  |
| snout.extent | 0.444 | 0.213 | -0.231 | -52 |  |
| neck.outer_width | 0.220 | 0.190 | -0.030 | -14 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.190 | +0.035 | +22 | y |
| neck.solid_width | 0.193 | 0.190 | -0.003 | -2 |  |
| neck.extent | 0.509 | 0.444 | -0.065 | -13 |  |
| neck_top.outer_width | 0.178 | 0.136 | -0.042 | -23 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.137 | +0.002 | +2 | y |
| neck_top.solid_width | 0.145 | 0.136 | -0.009 | -6 |  |
| neck_top.extent | 0.270 | 0.194 | -0.077 | -28 |  |
| neck_mid.outer_width | 0.133 | 0.121 | -0.013 | -9 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.121 | -0.013 | -9 | y |
| neck_mid.solid_width | 0.133 | 0.121 | -0.013 | -9 |  |
| neck_mid.extent | 0.139 | 0.151 | +0.012 | +8 |  |
| neck_base.outer_width | 0.366 | 0.334 | -0.033 | -9 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.334 | +0.120 | +56 | y |
| neck_base.solid_width | 0.335 | 0.334 | -0.002 | -0 |  |
| neck_base.extent | 0.389 | 0.398 | +0.010 | +3 |  |
| shoulders.outer_width | 0.585 | 0.628 | +0.044 | +7 | y |
| shoulders.solid_width | 0.585 | 0.628 | +0.044 | +7 |  |
| shoulders.extent | 0.668 | 0.645 | -0.023 | -3 |  |
| torso.outer_width | 0.783 | 0.684 | -0.099 | -13 | y |
| torso.solid_width | 0.733 | 0.682 | -0.051 | -7 |  |
| torso.extent | 1.103 | 0.810 | -0.293 | -27 |  |
| waist.outer_width | 0.897 | 0.747 | -0.151 | -17 | y |
| waist.solid_width | 0.827 | 0.747 | -0.080 | -10 |  |
| waist.extent | 0.928 | 0.754 | -0.175 | -19 |  |
| pelvis.outer_width | 0.966 | 0.776 | -0.191 | -20 | y |
| pelvis.solid_width | 0.921 | 0.763 | -0.158 | -17 |  |
| pelvis.extent | 1.053 | 0.810 | -0.243 | -23 |  |
| arm.outer_width | 0.839 | 0.723 | -0.116 | -14 |  |
| arm.solid_width | 0.790 | 0.703 | -0.087 | -11 |  |
| arm.extent | 1.103 | 0.859 | -0.243 | -22 |  |
| hand.outer_width | 0.908 | 0.771 | -0.137 | -15 |  |
| hand.solid_width | 0.879 | 0.699 | -0.179 | -20 |  |
| hand.extent | 1.111 | 0.876 | -0.235 | -21 |  |
| thigh.outer_width | 0.867 | 0.757 | -0.110 | -13 | y |
| thigh.solid_width | 0.862 | 0.619 | -0.243 | -28 |  |
| thigh.extent | 0.914 | 0.873 | -0.041 | -4 |  |
| shin.outer_width | 0.839 | 0.621 | -0.218 | -26 | y |
| shin.solid_width | 0.564 | 0.354 | -0.210 | -37 |  |
| shin.extent | 0.939 | 0.682 | -0.258 | -27 |  |
| foot.outer_width | 0.681 | 0.730 | +0.049 | +7 | y |
| foot.solid_width | 0.387 | 0.366 | -0.020 | -5 |  |
| foot.extent | 0.936 | 0.776 | -0.159 | -17 |  |
| total_height (highest point) | 2.400 | 2.394 | -0.006 | -0 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. back horn_A(image-right).tip_height: ref 2.362 m, model 2.386 m, err +0.024 m (+1%)
2. back foot.outer_width: ref 0.708 m, model 0.730 m, err +0.022 m (+3%)
3. side horn_B(front/long).span: ref 0.183 m, model 0.203 m, err +0.021 m (+11%)
4. side horns.total_depth_spread (side): ref 0.334 m, model 0.355 m, err +0.020 m (+6%)
5. side horn_A(rear/thick).span: ref 0.217 m, model 0.237 m, err +0.020 m (+9%)
6. back horns.total_spread (back, outer tip to outer tip): ref 0.393 m, model 0.413 m, err +0.020 m (+5%)
7. side foot.outer_width: ref 0.235 m, model 0.252 m, err +0.017 m (+7%)
8. side shoulders.outer_width: ref 0.402 m, model 0.418 m, err +0.016 m (+4%)
