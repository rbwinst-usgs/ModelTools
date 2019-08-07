# Hypothetical simulator of lake and surficial aquifer interaction. ------------
# Shows convergence to equilibrium in transient mode.
# Basic Package file created on 12/12/2015 by ModelMuse version 3.6.3.5.
FREE  # OPTIONS
INTERNAL 1 (FREE)        5 # IBOUND Layer 1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     0     0     0     0
     0     1     1     1     1     1     1
     1     1     1     1     1     1     0     0     0     0
     0     1     1     1     1     1     1
     1     1     1     1     1     1     0     0     0     0
     0     1     1     1     1     1     1
     1     1     1     1     1     1     0     0     0     0
     0     1     1     1     1     1     1
     1     1     1     1     1     1     0     0     0     0
     0     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
INTERNAL 1 (FREE)        5 # IBOUND Layer 2
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     0     0     0
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     0     0     0
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     0     0     0
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
     1     1     1     1     1     1     1     1     1     1
     1     1     1     1     1     1     1
CONSTANT        1 # IBOUND Layer 3
CONSTANT        1 # IBOUND Layer 4
CONSTANT        1 # IBOUND Layer 5
 -9.990000000000E+002  # HNOFLO
CONSTANT     1.150000000000E+002  # STRT Layer 1
CONSTANT     1.150000000000E+002  # STRT Layer 2
CONSTANT     1.150000000000E+002  # STRT Layer 3
CONSTANT     1.150000000000E+002  # STRT Layer 4
CONSTANT     1.150000000000E+002  # STRT Layer 5