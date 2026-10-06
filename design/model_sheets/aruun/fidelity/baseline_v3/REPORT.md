# Fidelity comparison (model - reference)

model: `game/art/models/aruun/aruun.glb`  forward +z  render height 2.382 m (top 2.383); mace islands dropped: 1437 faces

| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |
|---|---|---|---|---|---|---|
| side | 0.697 | 0.535 | -0.076 | 1.26 | 0.667 | +0.116 |
| back | 0.852 | 0.843 | +0.007 | 1.02 | 0.139 | +0.020 |
| front (3/4 ref, qualitative) | 0.575 | 0.457 | +0.143 | 0.85 | 0.301 | -0.076 |

## side region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.193 | 0.133 | -0.060 | -31 |  |
| horns.solid_width | 0.119 | 0.130 | +0.010 | +9 |  |
| horns.extent | 0.381 | 0.473 | +0.092 | +24 |  |
| head.outer_width | 0.226 | 0.486 | +0.259 | +115 |  |
| head.run_width (central run, fringe/skirt-free) | 0.200 | 0.400 | +0.200 | +100 |  |
| head.solid_width | 0.213 | 0.443 | +0.230 | +108 |  |
| head.extent | 0.307 | 0.644 | +0.336 | +109 |  |
| snout.outer_width | 0.236 | 0.557 | +0.321 | +136 |  |
| snout.solid_width | 0.218 | 0.499 | +0.281 | +129 |  |
| snout.extent | 0.307 | 0.644 | +0.336 | +109 |  |
| neck.outer_width | 0.150 | 0.371 | +0.221 | +147 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.147 | 0.188 | +0.040 | +27 | y |
| neck.solid_width | 0.149 | 0.236 | +0.087 | +58 |  |
| neck.extent | 0.314 | 0.661 | +0.347 | +111 |  |
| neck_top.outer_width | 0.108 | 0.603 | +0.495 | +456 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.108 | 0.256 | +0.147 | +136 | y |
| neck_top.solid_width | 0.108 | 0.315 | +0.207 | +191 |  |
| neck_top.extent | 0.110 | 0.654 | +0.544 | +494 |  |
| neck_mid.outer_width | 0.115 | 0.197 | +0.082 | +72 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.115 | 0.124 | +0.009 | +8 | y |
| neck_mid.solid_width | 0.115 | 0.128 | +0.013 | +11 |  |
| neck_mid.extent | 0.124 | 0.403 | +0.278 | +224 |  |
| neck_base.outer_width | 0.252 | 0.345 | +0.093 | +37 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.245 | 0.220 | -0.025 | -10 | y |
| neck_base.solid_width | 0.250 | 0.313 | +0.063 | +25 |  |
| neck_base.extent | 0.314 | 0.374 | +0.061 | +19 |  |
| shoulders.outer_width | 0.402 | 0.466 | +0.064 | +16 | y |
| shoulders.solid_width | 0.402 | 0.443 | +0.041 | +10 |  |
| shoulders.extent | 0.436 | 0.499 | +0.062 | +14 |  |
| torso.outer_width | 0.423 | 0.521 | +0.098 | +23 |  |
| torso.solid_width | 0.413 | 0.446 | +0.033 | +8 |  |
| torso.extent | 0.537 | 0.611 | +0.074 | +14 |  |
| waist.outer_width | 0.460 | 0.528 | +0.067 | +15 | y |
| waist.solid_width | 0.460 | 0.463 | +0.002 | +0 |  |
| waist.extent | 0.468 | 0.549 | +0.081 | +17 |  |
| pelvis.outer_width | 0.419 | 0.609 | +0.190 | +45 |  |
| pelvis.solid_width | 0.405 | 0.536 | +0.131 | +32 |  |
| pelvis.extent | 0.446 | 0.611 | +0.165 | +37 |  |
| arm.outer_width | 0.399 | 0.552 | +0.154 | +38 |  |
| arm.solid_width | 0.387 | 0.469 | +0.083 | +21 |  |
| arm.extent | 0.537 | 0.615 | +0.079 | +15 |  |
| hand.outer_width | 0.302 | 0.611 | +0.309 | +102 |  |
| hand.solid_width | 0.294 | 0.525 | +0.230 | +78 |  |
| hand.extent | 0.463 | 0.617 | +0.154 | +33 |  |
| thigh.outer_width | 0.192 | 0.586 | +0.395 | +206 |  |
| thigh.solid_width | 0.187 | 0.421 | +0.234 | +125 |  |
| thigh.extent | 0.360 | 0.618 | +0.258 | +72 |  |
| shin.outer_width | 0.117 | 0.126 | +0.009 | +8 | y |
| shin.solid_width | 0.117 | 0.118 | +0.000 | +0 |  |
| shin.extent | 0.198 | 0.409 | +0.211 | +107 |  |
| foot.outer_width | 0.235 | 0.247 | +0.012 | +5 | y |
| foot.solid_width | 0.229 | 0.240 | +0.011 | +5 |  |
| foot.extent | 0.416 | 0.549 | +0.133 | +32 |  |
| snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment) | 0.130 | 0.268 | +0.138 | +106 | y |
| head.length (nape..snout tip) | 0.307 | 0.644 | +0.336 | +109 | y |
| foot.length (heel..toe) | 0.416 | 0.549 | +0.133 | +32 | y |
| torso.chest_to_back_depth | 0.513 | 0.570 | +0.057 | +11 | y |
| head.snout_tip_height | 2.008 | 1.995 | -0.013 | -1 |  |
| total_height (highest point) | 2.400 | 2.383 | -0.017 | -1 | y |
| horn_A(rear/thick).tip_height | 2.400 | 2.383 | -0.017 | -1 | y |
| horn_A(rear/thick).span | 0.217 | 0.369 | +0.152 | +70 | y |
| horns.total_depth_spread (side) | 0.334 | 0.369 | +0.035 | +10 | y |

## back region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.191 | 0.245 | +0.054 | +29 |  |
| horns.solid_width | 0.119 | 0.143 | +0.024 | +20 |  |
| horns.extent | 0.439 | 0.467 | +0.028 | +6 |  |
| head.outer_width | 0.210 | 0.332 | +0.122 | +58 |  |
| head.run_width (central run, fringe/skirt-free) | 0.204 | 0.311 | +0.108 | +53 |  |
| head.solid_width | 0.207 | 0.330 | +0.123 | +59 |  |
| head.extent | 0.331 | 0.389 | +0.058 | +17 |  |
| snout.outer_width | 0.195 | 0.356 | +0.161 | +83 |  |
| snout.solid_width | 0.194 | 0.354 | +0.160 | +83 |  |
| snout.extent | 0.258 | 0.389 | +0.131 | +51 |  |
| neck.outer_width | 0.198 | 0.254 | +0.056 | +28 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.178 | 0.200 | +0.022 | +12 | y |
| neck.solid_width | 0.191 | 0.228 | +0.037 | +20 |  |
| neck.extent | 0.458 | 0.519 | +0.061 | +13 |  |
| neck_top.outer_width | 0.142 | 0.327 | +0.185 | +130 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.133 | 0.172 | +0.039 | +29 | y |
| neck_top.solid_width | 0.138 | 0.240 | +0.102 | +74 |  |
| neck_top.extent | 0.224 | 0.376 | +0.151 | +67 |  |
| neck_mid.outer_width | 0.122 | 0.147 | +0.025 | +20 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.122 | 0.147 | +0.025 | +20 | y |
| neck_mid.solid_width | 0.122 | 0.147 | +0.025 | +20 |  |
| neck_mid.extent | 0.133 | 0.159 | +0.026 | +19 |  |
| neck_base.outer_width | 0.345 | 0.335 | -0.010 | -3 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.326 | 0.323 | -0.002 | -1 | y |
| neck_base.solid_width | 0.344 | 0.335 | -0.009 | -3 |  |
| neck_base.extent | 0.409 | 0.392 | -0.017 | -4 |  |
| shoulders.outer_width | 0.625 | 0.636 | +0.011 | +2 | y |
| shoulders.solid_width | 0.625 | 0.636 | +0.011 | +2 |  |
| shoulders.extent | 0.639 | 0.648 | +0.009 | +1 |  |
| torso.outer_width | 0.675 | 0.692 | +0.017 | +3 | y |
| torso.solid_width | 0.666 | 0.675 | +0.009 | +1 |  |
| torso.extent | 0.812 | 0.829 | +0.017 | +2 |  |
| waist.outer_width | 0.743 | 0.748 | +0.006 | +1 | y |
| waist.solid_width | 0.742 | 0.701 | -0.041 | -6 |  |
| waist.extent | 0.751 | 0.758 | +0.007 | +1 |  |
| pelvis.outer_width | 0.784 | 0.800 | +0.016 | +2 | y |
| pelvis.solid_width | 0.745 | 0.792 | +0.047 | +6 |  |
| pelvis.extent | 0.812 | 0.829 | +0.017 | +2 |  |
| arm.outer_width | 0.712 | 0.728 | +0.016 | +2 |  |
| arm.solid_width | 0.691 | 0.701 | +0.010 | +1 |  |
| arm.extent | 0.861 | 0.856 | -0.005 | -1 |  |
| hand.outer_width | 0.770 | 0.787 | +0.017 | +2 |  |
| hand.solid_width | 0.696 | 0.719 | +0.023 | +3 |  |
| hand.extent | 0.882 | 0.856 | -0.026 | -3 |  |
| thigh.outer_width | 0.755 | 0.745 | -0.010 | -1 | y |
| thigh.solid_width | 0.627 | 0.604 | -0.023 | -4 |  |
| thigh.extent | 0.889 | 0.823 | -0.066 | -7 |  |
| shin.outer_width | 0.606 | 0.596 | -0.010 | -2 | y |
| shin.solid_width | 0.350 | 0.327 | -0.023 | -7 |  |
| shin.extent | 0.668 | 0.657 | -0.010 | -2 |  |
| foot.outer_width | 0.708 | 0.683 | -0.025 | -4 | y |
| foot.solid_width | 0.357 | 0.332 | -0.025 | -7 |  |
| foot.extent | 0.829 | 0.797 | -0.033 | -4 |  |
| total_height (highest point) | 2.400 | 2.383 | -0.017 | -1 | y |
| horn_B(image-left).tip_height | 2.400 | 2.383 | -0.017 | -1 | y |
| horn_B(image-left).span | 0.290 | 0.324 | +0.034 | +12 | y |
| horn_A(image-right).tip_height | 2.362 | 2.378 | +0.016 | +1 | y |
| horn_A(image-right).span | 0.103 | 0.120 | +0.017 | +17 | y |
| horns.total_spread (back, outer tip to outer tip) | 0.393 | 0.444 | +0.051 | +13 | y |
| hand.bottom_height (arm length proxy) | 0.772 | 0.629 | -0.143 | -18 |  |
| arm.arm_length_shoulder_to_hand (vertical) | 0.859 | 1.002 | +0.143 | +17 |  |

## front region errors (m; err = model - ref; edge uncertainty about +-0.0037 m)

| region | ref m | model m | err m | err % | rank? |
|---|---|---|---|---|---|
| horns.outer_width | 0.202 | 0.245 | +0.043 | +21 |  |
| horns.solid_width | 0.113 | 0.143 | +0.030 | +27 |  |
| horns.extent | 0.473 | 0.467 | -0.006 | -1 |  |
| head.outer_width | 0.323 | 0.332 | +0.009 | +3 |  |
| head.run_width (central run, fringe/skirt-free) | 0.259 | 0.280 | +0.021 | +8 |  |
| head.solid_width | 0.291 | 0.330 | +0.039 | +13 |  |
| head.extent | 0.484 | 0.388 | -0.096 | -20 |  |
| snout.outer_width | 0.319 | 0.356 | +0.036 | +11 |  |
| snout.solid_width | 0.300 | 0.354 | +0.054 | +18 |  |
| snout.extent | 0.444 | 0.388 | -0.057 | -13 |  |
| neck.outer_width | 0.220 | 0.254 | +0.034 | +15 |  |
| neck.run_width (central run, fringe/skirt-free) | 0.155 | 0.200 | +0.045 | +29 | y |
| neck.solid_width | 0.193 | 0.228 | +0.035 | +18 |  |
| neck.extent | 0.509 | 0.519 | +0.010 | +2 |  |
| neck_top.outer_width | 0.178 | 0.327 | +0.149 | +84 |  |
| neck_top.run_width (central run, fringe/skirt-free) | 0.134 | 0.172 | +0.038 | +28 | y |
| neck_top.solid_width | 0.145 | 0.240 | +0.095 | +65 |  |
| neck_top.extent | 0.270 | 0.375 | +0.105 | +39 |  |
| neck_mid.outer_width | 0.133 | 0.147 | +0.014 | +10 |  |
| neck_mid.run_width (central run, fringe/skirt-free) | 0.133 | 0.147 | +0.014 | +10 | y |
| neck_mid.solid_width | 0.133 | 0.147 | +0.014 | +10 |  |
| neck_mid.extent | 0.139 | 0.160 | +0.021 | +15 |  |
| neck_base.outer_width | 0.366 | 0.335 | -0.031 | -8 |  |
| neck_base.run_width (central run, fringe/skirt-free) | 0.214 | 0.322 | +0.108 | +51 | y |
| neck_base.solid_width | 0.335 | 0.335 | -0.001 | -0 |  |
| neck_base.extent | 0.389 | 0.392 | +0.004 | +1 |  |
| shoulders.outer_width | 0.585 | 0.636 | +0.051 | +9 | y |
| shoulders.solid_width | 0.585 | 0.636 | +0.051 | +9 |  |
| shoulders.extent | 0.668 | 0.647 | -0.021 | -3 |  |
| torso.outer_width | 0.783 | 0.692 | -0.090 | -12 | y |
| torso.solid_width | 0.733 | 0.675 | -0.058 | -8 |  |
| torso.extent | 1.103 | 0.829 | -0.274 | -25 |  |
| waist.outer_width | 0.897 | 0.748 | -0.149 | -17 | y |
| waist.solid_width | 0.827 | 0.701 | -0.126 | -15 |  |
| waist.extent | 0.928 | 0.758 | -0.170 | -18 |  |
| pelvis.outer_width | 0.966 | 0.800 | -0.166 | -17 | y |
| pelvis.solid_width | 0.921 | 0.792 | -0.129 | -14 |  |
| pelvis.extent | 1.053 | 0.829 | -0.224 | -21 |  |
| arm.outer_width | 0.839 | 0.728 | -0.111 | -13 |  |
| arm.solid_width | 0.790 | 0.701 | -0.088 | -11 |  |
| arm.extent | 1.103 | 0.856 | -0.247 | -22 |  |
| hand.outer_width | 0.908 | 0.787 | -0.121 | -13 |  |
| hand.solid_width | 0.879 | 0.719 | -0.160 | -18 |  |
| hand.extent | 1.111 | 0.856 | -0.256 | -23 |  |
| thigh.outer_width | 0.867 | 0.745 | -0.122 | -14 | y |
| thigh.solid_width | 0.862 | 0.604 | -0.257 | -30 |  |
| thigh.extent | 0.914 | 0.823 | -0.090 | -10 |  |
| shin.outer_width | 0.839 | 0.596 | -0.243 | -29 | y |
| shin.solid_width | 0.564 | 0.327 | -0.237 | -42 |  |
| shin.extent | 0.939 | 0.658 | -0.282 | -30 |  |
| foot.outer_width | 0.681 | 0.683 | +0.001 | +0 | y |
| foot.solid_width | 0.387 | 0.332 | -0.055 | -14 |  |
| foot.extent | 0.936 | 0.797 | -0.138 | -15 |  |
| total_height (highest point) | 2.400 | 2.383 | -0.017 | -1 | y |

## Largest deviations (rankable regions, side+back, by |err| in m)

1. side head.length (nape..snout tip): ref 0.307 m, model 0.644 m, err +0.336 m (+109%)
2. side horn_A(rear/thick).span: ref 0.217 m, model 0.369 m, err +0.152 m (+70%)
3. side neck_top.run_width (central run, fringe/skirt-free): ref 0.108 m, model 0.256 m, err +0.147 m (+136%)
4. side snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment): ref 0.130 m, model 0.268 m, err +0.138 m (+106%)
5. side foot.length (heel..toe): ref 0.416 m, model 0.549 m, err +0.133 m (+32%)
6. side waist.outer_width: ref 0.460 m, model 0.528 m, err +0.067 m (+15%)
7. side shoulders.outer_width: ref 0.402 m, model 0.466 m, err +0.064 m (+16%)
8. side torso.chest_to_back_depth: ref 0.513 m, model 0.570 m, err +0.057 m (+11%)
