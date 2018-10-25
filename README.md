# Contrail VRouter Statistics

## Take Network Statistics for Kernel
Generate Linux, VRouter, and KVM network statistics

## Take Network Statistics for DPDK
Generate VRouter-DPDK network statistics

### Example output
```
########## Contrail vRouter VIF STATS over 300 seconds ############
               VIF               TAP            TX            RX         Drops     TX Errors     RX Errors        TX PPS        RX PPS   TX & RX PPS     Drops PPS   TX port sys   RX port sys   TX port err   RX port err  RX queue Err
            vif0/0      vrouter_bond         51883        105883        236736             0             0        172.94        352.94        525.88        789.12             0             0             0             0             0
            vif0/3    tap941e4e8a-ce         53976         24465           915             0             0        179.92         81.55        261.47          3.05         27132             0             0             0             0
           vif0/15    tap4187f217-d0         18018          6052         17829             0             0         60.06         20.17         80.23         59.43             0             0             0             0             0
           vif0/16    tap62aa8528-14         17928          5976         17829             0             0         59.76         19.92         79.68         59.43             0             0             0             0             0
           vif0/17    tap6c63a09d-3b         17882          6002         17829             0             0         59.60         20.00         79.60         59.43             0             0             0             0             0
           vif0/18    tap976b7ff8-7c         17911          6003         17829             0             0         59.70         20.01         79.71         59.43             0             0             0             0             0
           vif0/19    tap8b210572-cb            60             0             0             0             0           .20             0           .20             0             0             0             0             0             0
           vif0/20    tap158202fb-d5            60             0             0             0             0           .20             0           .20             0             0             0             0             0             0
           vif0/21    tap99ed4f87-78           180             0             0             0             0           .60             0           .60             0             0             0             0             0             0
           vif0/22    tap772f84c6-88           180             0             0             0             0           .60             0           .60             0             0             0             0             0             0
            vif0/9           vif0/19            68            75             0             0             0           .22           .25           .47             0             0             0             0             0             0
            vif0/8           vif0/20            72            79             0             0             0           .24           .26           .50             0             0             0             0             0             0
            vif0/5           vif0/21            73            80             0             0             0           .24           .26           .50             0             0             0             0             0             0
           vif0/11           vif0/21            72            79             0             0             0           .24           .26           .50             0             0             0             0             0             0
           vif0/13           vif0/21            66            72             0             0             0           .22           .24           .46             0             0             0             0             0             0
           vif0/14           vif0/21            67            73             0             0             0           .22           .24           .46             0             0             0             0             0             0
           vif0/23           vif0/21            71            77             0             0             0           .23           .25           .48             0             0             0             0             0             0
            vif0/4           vif0/22            30            23            23             0             0           .10           .07           .17           .07             0             0             0             0             0
            vif0/6           vif0/22            30            24            24             0             0           .10           .08           .18           .08             0             0             0             0             0
            vif0/7           vif0/22            30            23            23             0             0           .10           .07           .17           .07             0             0             0             0             0
           vif0/10           vif0/22            30            25            25             0             0           .10           .08           .18           .08             0             0             0             0             0
           vif0/12           vif0/22            30            23            23             0             0           .10           .07           .17           .07             0             0             0             0             0


########## Contrail vRouter VIF STATS per CORE over 300 seconds ############


########## RX packets ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond         20158         10079         24373         51264
            vif0/3    tap941e4e8a-ce          3800         11620          4713          4343
           vif0/15    tap4187f217-d0             0             0          6048             0
           vif0/16    tap62aa8528-14             0             0             0          5973
           vif0/17    tap6c63a09d-3b          5998             0             0             0
           vif0/18    tap976b7ff8-7c             0          5999             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19            28            14            31             7
            vif0/8           vif0/20            14            14            21            30
            vif0/5           vif0/21            31             7            21            21
           vif0/11           vif0/21            30            14            14            21
           vif0/13           vif0/21            29            28             0            21
           vif0/14           vif0/21            30             7             7            28
           vif0/23           vif0/21            29             7             7            28
            vif0/4           vif0/22             0            23             0             0
            vif0/6           vif0/22             0            24             0             0
            vif0/7           vif0/22             0            22             0             0
           vif0/10           vif0/22             0            24             0             0
           vif0/12           vif0/22             0            23             0             0


########## RX packets errors ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce             0             0             0             0
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## TX packets ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond          9901         17787         10963         13177
            vif0/3    tap941e4e8a-ce         10367          7678         11118         24821
           vif0/15    tap4187f217-d0           208          5914            34         11851
           vif0/16    tap62aa8528-14          6041            50          5914          5914
           vif0/17    tap6c63a09d-3b             0            80         11827          5974
           vif0/18    tap976b7ff8-7c          6018            56             0         11827
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             1            42
            vif0/8           vif0/20             0             0            42             0
            vif0/5           vif0/21             1            42             0             0
           vif0/11           vif0/21             0            42             0             0
           vif0/13           vif0/21             0             0            42             0
           vif0/14           vif0/21             1             0            36             0
           vif0/23           vif0/21             0             0             0            36
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## TX packets errors ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce             0             0             0             0
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## RX syscalls ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce             0             0             0             0
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## TX syscalls ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce          4327          3111          5042         14660
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## RX port errors ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce             0             0             0             0
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## TX port errors ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce             0             0             0             0
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0


########## RX queue errors ############
               VIF               TAP        CORE10        CORE11        CORE12        CORE13
            vif0/0      vrouter_bond             0             0             0             0
            vif0/3    tap941e4e8a-ce             0             0             0             0
           vif0/15    tap4187f217-d0             0             0             0             0
           vif0/16    tap62aa8528-14             0             0             0             0
           vif0/17    tap6c63a09d-3b             0             0             0             0
           vif0/18    tap976b7ff8-7c             0             0             0             0
           vif0/19    tap8b210572-cb             0             0             0             0
           vif0/20    tap158202fb-d5             0             0             0             0
           vif0/21    tap99ed4f87-78             0             0             0             0
           vif0/22    tap772f84c6-88             0             0             0             0
            vif0/9           vif0/19             0             0             0             0
            vif0/8           vif0/20             0             0             0             0
            vif0/5           vif0/21             0             0             0             0
           vif0/11           vif0/21             0             0             0             0
           vif0/13           vif0/21             0             0             0             0
           vif0/14           vif0/21             0             0             0             0
           vif0/23           vif0/21             0             0             0             0
            vif0/4           vif0/22             0             0             0             0
            vif0/6           vif0/22             0             0             0             0
            vif0/7           vif0/22             0             0             0             0
           vif0/10           vif0/22             0             0             0             0
           vif0/12           vif0/22             0             0             0             0
```
