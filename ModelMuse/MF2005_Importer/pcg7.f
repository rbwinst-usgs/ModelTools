      MODULE PCGMODULE
        INTEGER,SAVE,POINTER  ::ITER1,NPCOND,NBPOL,IPRPCG,MUTPCG,NITER
        REAL   ,SAVE,POINTER  ::HCLOSEPCG,RCLOSEPCG,RELAXPCG,DAMPPCG
        REAL   ,SAVE,POINTER  ::DAMPPCGT
        INTEGER,SAVE,POINTER  ::IHCOFADD
        DOUBLE PRECISION, SAVE, POINTER, DIMENSION(:,:,:) ::VPCG
        DOUBLE PRECISION, SAVE, POINTER, DIMENSION(:,:,:) ::SS
        DOUBLE PRECISION, SAVE, POINTER, DIMENSION(:,:,:) ::P
        DOUBLE PRECISION, SAVE, POINTER, DIMENSION(:,:,:) ::HPCG
        REAL,             SAVE, POINTER, DIMENSION(:,:,:) ::CD
        REAL,             SAVE, POINTER, DIMENSION(:,:,:) ::HCSV
        INTEGER,          SAVE, POINTER, DIMENSION(:,:)   ::LHCH
        REAL,             SAVE, POINTER, DIMENSION(:)     ::HCHG
        INTEGER,          SAVE, POINTER, DIMENSION(:,:)   ::LRCHPCG
        REAL,             SAVE, POINTER, DIMENSION(:)     ::RCHG
        INTEGER,          SAVE, POINTER, DIMENSION(:)     ::IT1
      TYPE PCGTYPE
        INTEGER,POINTER  ::ITER1,NPCOND,NBPOL,IPRPCG,MUTPCG,NITER
        REAL   ,POINTER  ::HCLOSEPCG,RCLOSEPCG,RELAXPCG,DAMPPCG
        REAL   ,POINTER  :: DAMPPCGT
        INTEGER,POINTER  ::IHCOFADD
        DOUBLE PRECISION,  POINTER, DIMENSION(:,:,:) ::VPCG
        DOUBLE PRECISION,  POINTER, DIMENSION(:,:,:) ::SS
        DOUBLE PRECISION,  POINTER, DIMENSION(:,:,:) ::P
        DOUBLE PRECISION,  POINTER, DIMENSION(:,:,:) ::HPCG
        REAL,              POINTER, DIMENSION(:,:,:) ::CD
        REAL,              POINTER, DIMENSION(:,:,:) ::HCSV
        INTEGER,           POINTER, DIMENSION(:,:)   ::LHCH
        REAL,              POINTER, DIMENSION(:)     ::HCHG
        INTEGER,           POINTER, DIMENSION(:,:)   ::LRCHPCG
        REAL,              POINTER, DIMENSION(:)     ::RCHG
        INTEGER,           POINTER, DIMENSION(:)     ::IT1
      END TYPE
      TYPE(PCGTYPE), SAVE ::PCGDAT(10)
      END MODULE PCGMODULE


      SUBROUTINE PCG7AR(IN,MXITER,IGRID)
C     ******************************************************************
C     ALLOCATE STORAGE FOR PCG ARRAYS AND READ PCG DATA
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY
      USE PCGMODULE,ONLY:ITER1,NPCOND,NBPOL,IPRPCG,MUTPCG,NITER,
     1                   HCLOSEPCG,RCLOSEPCG,RELAXPCG,DAMPPCG,VPCG,SS,P,
     2                   HPCG,CD,HCSV,LHCH,HCHG,LRCHPCG,RCHG,IT1,
     3                   DAMPPCGT,
     4                   IHCOFADD  !JDH 20110814
C
      CHARACTER*200 LINE
      INTEGER IN,MXITER
C     ------------------------------------------------------------------
      ALLOCATE(ITER1,NPCOND,NBPOL,IPRPCG,MUTPCG,NITER)
      ALLOCATE(HCLOSEPCG,RCLOSEPCG,RELAXPCG,DAMPPCG,DAMPPCGT)
      ALLOCATE(IHCOFADD)
C
C-------PRINT A MESSAGE IDENTIFYING PCG PACKAGE
      WRITE (IOUT,*)'PCG:'
!      WRITE (IOUT,500)
!  500 FORMAT (1X,/1X,'PCG -- CONJUGATE-GRADIENT SOLUTION PACKAGE',
!     &        ', VERSION 7, 5/2/2005')
C
C-------READ AND PRINT COMMENTS, MXITER,ITER1 AND NPCOND
      CALL URDCOM(IN,IOUT,LINE)
      LLOC=1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXITER,R,IOUT,IN)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ITER1,R,IOUT,IN)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NPCOND,R,IOUT,IN)
C  JDH 20110814 - ADDED IHCOFADD
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHCOFADD,R,-IOUT,IN)
      WRITE (IOUT,*) 'MXITER, ITER1, NPCOND, IHCOFADD:'
      WRITE (IOUT,*) MXITER, ITER1, NPCOND, IHCOFADD
!      WRITE (IOUT,510) MXITER, ITER1, NPCOND
!  510 FORMAT (' MAXIMUM OF ',I6,' CALLS OF SOLUTION ROUTINE',/,
!     &        ' MAXIMUM OF ',I6,
!     &        ' INTERNAL ITERATIONS PER CALL TO SOLUTION ROUTINE',/,
!     &        ' MATRIX PRECONDITIONING TYPE :',I5)
C
C-------ALLOCATE SPACE FOR THE PCG ARRAYS
      ALLOCATE (VPCG(NCOL,NROW,NLAY))
      ALLOCATE (SS(NCOL,NROW,NLAY))
      ALLOCATE (P(NCOL,NROW,NLAY))
      ALLOCATE (HPCG(NCOL,NROW,NLAY))
      ALLOCATE (CD(NCOL,NROW,NLAY))
      IF(NPCOND.EQ.2) THEN
         ALLOCATE (HCSV(NCOL,NROW,NLAY))
      ELSE
         ALLOCATE (HCSV(1,1,1))
      END IF
      ITMEM=MXITER*ITER1
      ALLOCATE (HCHG(ITMEM))
      ALLOCATE (LHCH(3,ITMEM))
      ALLOCATE (RCHG(ITMEM))
      ALLOCATE (LRCHPCG(3,ITMEM))
      ALLOCATE (IT1(ITMEM))
C
C-------READ HCLOSEPCG,RCLOSEPCG,RELAXPCG,NBPOL,IPRPCG,MUTPCG
      READ (IN,*, ERR=1000) HCLOSEPCG,RCLOSEPCG,RELAXPCG,
     1    NBPOL,IPRPCG,MUTPCG,DAMPPCG
      IF ( DAMPPCG.LT.0.0 ) THEN
        BACKSPACE IN
        READ (IN,*) HCLOSEPCG,RCLOSEPCG,RELAXPCG,
     1    NBPOL,IPRPCG,MUTPCG,DAMPPCG,DAMPPCGT
          DAMPPCG = -DAMPPCG
          IF (DAMPPCGT.EQ.0.0) DAMPPCGT = 1.0
      ELSE
        IF (DAMPPCG.EQ.0.0) DAMPPCG = 1.0
        DAMPPCGT = DAMPPCG
      END IF 
      Goto 2000 
1000  READ (IN,500) HCLOSEPCG
!1000  READ (IN,500) HCLOSEPCG,RCLOSEPCG,RELAXPCG,
!     1    NBPOL,IPRPCG,MUTPCG,DAMPPCG
  500    FORMAT (3F10.0,3I10,F10.0)
        DAMPPCGT = DAMPPCG
2000  Continue                                       
      WRITE (IOUT,*) 
     1 'HCLOSEPCG,RCLOSEPCG,RELAXPCG,NBPOL,IPRPCG,MUTPCG,DAMPPCG:'
      WRITE (IOUT,*) HCLOSEPCG,RCLOSEPCG,RELAXPCG,
     1    NBPOL,IPRPCG,MUTPCG,DAMPPCG,DAMPPCGT
C
C-------PRINT MXITER,ITER1,NPCOND,HCLOSEPCG,RCLOSEPCG,RELAXPCG,NBPOL,IPRPCG,
C-------MUTPCG,DAMPPCG
!        WRITE (IOUT,511)
!  511   FORMAT (1X,///,36X,'SOLUTION BY THE CONJUGATE-GRADIENT METHOD',
!     &        /,35X,43('-'))
!      WRITE (IOUT,512) MXITER
!  512 FORMAT (1X,19X,'MAXIMUM NUMBER OF CALLS TO PCG ROUTINE =',I9)
!      WRITE (IOUT,515) ITER1
!  515 FORMAT (1X,23X,'MAXIMUM ITERATIONS PER CALL TO PCG =',I9)
!      WRITE (IOUT,520) NPCOND
!  520 FORMAT (1X,30X,'MATRIX PRECONDITIONING TYPE =',I9)
!      IF (NPCOND.EQ.2) WRITE (IOUT,525)
!  525 FORMAT (1X,53X,'THE MATRIX WILL BE SCALED')
!      WRITE (IOUT,530) RELAXPCG, NBPOL
!  530 FORMAT (1X,7X,'RELAXATION FACTOR (ONLY USED WITH',
!     &        ' PRECOND. TYPE 1) =',E15.5,/,1X,
!     &        'PARAMETER OF POLYNOMIAL PRECOND.',
!     &        ' = 2 (2) OR IS CALCULATED :',I9)
!      WRITE (IOUT,535) HCLOSEPCG
!  535 FORMAT (1X,24X,'HEAD CHANGE CRITERION FOR CLOSURE =',E15.5)
!      WRITE (IOUT,540) RCLOSEPCG
!  540 FORMAT (1X,20X,'RESIDUAL CHANGE CRITERION FOR CLOSURE =',E15.5)
!      IF (IPRPCG.LE.0) IPRPCG = 999
!      WRITE (IOUT,545) IPRPCG, MUTPCG
!  545 FORMAT (1X,11X,'PCG HEAD AND RESIDUAL CHANGE PRINTOUT INTERVAL =',
!     &        I9,/,1X,4X,
!     &        'PRINTING FROM SOLVER IS LIMITED(1) OR SUPPRESSED (>1) =',
!     &        I9)
!      WRITE (IOUT,550) DAMPPCG,DAMPPCGT
!  550 FORMAT (1X,27X,'STEADY-STATE DAMPING PARAMETER =',E15.5
!     &       /1X,30X,'TRANSIENT DAMPING PARAMETER =',E15.5)
      NITER = 0
C
      CALL PCG7PSV(IGRID)
      RETURN
      END
!      SUBROUTINE PCG7AP(HNEW,IBOUND,CR,CC,CV,HCOF,RHS,V,SS,P,CD,HCHG,
!     &                  LHCH,RCHG,LRCH,KITER,NITER,HCLOSE,RCLOSE,
!     &                  ICNVG,KSTP,KPER,IPRPCG,MXITER,ITER1,NPCOND,
!     &                  NBPOL,NSTP,NCOL,NROW,NLAY,NODES,RELAX,IOUT,
!     &                  MUTPCG,IT1,DAMP,RES,HCSV,IERR,HPCG)
!      SUBROUTINE SPCG7P(HCHG,LHCH,RCHG,LRCH,ITER1,NITER,MXITER,IOUT,
!     &                  NPCOND,BPOLY,IT1,MUTPCG,NCOL,NROW)
C     ******************************************************************
C     PRINT MAXIMUM HEAD CHANGE AND RESIDUAL VALUE FOR EACH ITERATION
C                           DURING A TIME STEP
C     ******************************************************************
C
C
!      SUBROUTINE SPCG7E(IBOUND,RES,HCOF,CR,CC,CV,VIN,VOUT,C,NORM,NCOL,
!     &                  NROW,NLAY,NODES)
C     ******************************************************************
C           MATRIX MULTIPLICATIONS FOR POLYNOMIAL PRECONDITIONING
C     ******************************************************************
      SUBROUTINE PCG7DA(IGRID)
C  Deallocate PCG DATA
      USE PCGMODULE
C
      CALL PCG7PNT(IGRID)
        DEALLOCATE(ITER1,NPCOND,NBPOL,IPRPCG,MUTPCG,NITER)
        DEALLOCATE(HCLOSEPCG,RCLOSEPCG,RELAXPCG,DAMPPCG,DAMPPCGT)
        DEALLOCATE(IHCOFADD)
        DEALLOCATE(VPCG)
        DEALLOCATE(SS)
        DEALLOCATE(P)
        DEALLOCATE(HPCG)
        DEALLOCATE(CD)
        DEALLOCATE(HCSV)
        DEALLOCATE(LHCH)
        DEALLOCATE(HCHG)
        DEALLOCATE(LRCHPCG)
        DEALLOCATE(RCHG)
        DEALLOCATE(IT1)
C
      RETURN
      END
      SUBROUTINE PCG7PNT(IGRID)
C  Set pointers to PCG data for a grid
      USE PCGMODULE
C
      ITER1=>PCGDAT(IGRID)%ITER1
      NPCOND=>PCGDAT(IGRID)%NPCOND
      NBPOL=>PCGDAT(IGRID)%NBPOL
      IPRPCG=>PCGDAT(IGRID)%IPRPCG
      MUTPCG=>PCGDAT(IGRID)%MUTPCG
      NITER=>PCGDAT(IGRID)%NITER
      HCLOSEPCG=>PCGDAT(IGRID)%HCLOSEPCG
      RCLOSEPCG=>PCGDAT(IGRID)%RCLOSEPCG
      RELAXPCG=>PCGDAT(IGRID)%RELAXPCG
      DAMPPCG=>PCGDAT(IGRID)%DAMPPCG
      DAMPPCGT=>PCGDAT(IGRID)%DAMPPCGT
      IHCOFADD=>PCGDAT(IGRID)%IHCOFADD
      VPCG=>PCGDAT(IGRID)%VPCG
      SS=>PCGDAT(IGRID)%SS
      P=>PCGDAT(IGRID)%P
      HPCG=>PCGDAT(IGRID)%HPCG
      CD=>PCGDAT(IGRID)%CD
      HCSV=>PCGDAT(IGRID)%HCSV
      LHCH=>PCGDAT(IGRID)%LHCH
      HCHG=>PCGDAT(IGRID)%HCHG
      LRCHPCG=>PCGDAT(IGRID)%LRCHPCG
      RCHG=>PCGDAT(IGRID)%RCHG
      IT1=>PCGDAT(IGRID)%IT1
C
      RETURN
      END

      SUBROUTINE PCG7PSV(IGRID)
C  Save pointers to PCG data
      USE PCGMODULE
C
      PCGDAT(IGRID)%ITER1=>ITER1
      PCGDAT(IGRID)%NPCOND=>NPCOND
      PCGDAT(IGRID)%NBPOL=>NBPOL
      PCGDAT(IGRID)%IPRPCG=>IPRPCG
      PCGDAT(IGRID)%MUTPCG=>MUTPCG
      PCGDAT(IGRID)%NITER=>NITER
      PCGDAT(IGRID)%HCLOSEPCG=>HCLOSEPCG
      PCGDAT(IGRID)%RCLOSEPCG=>RCLOSEPCG
      PCGDAT(IGRID)%RELAXPCG=>RELAXPCG
      PCGDAT(IGRID)%DAMPPCG=>DAMPPCG
      PCGDAT(IGRID)%DAMPPCGT=>DAMPPCGT
      PCGDAT(IGRID)%IHCOFADD=>IHCOFADD
      PCGDAT(IGRID)%VPCG=>VPCG
      PCGDAT(IGRID)%SS=>SS
      PCGDAT(IGRID)%P=>P
      PCGDAT(IGRID)%HPCG=>HPCG
      PCGDAT(IGRID)%CD=>CD
      PCGDAT(IGRID)%HCSV=>HCSV
      PCGDAT(IGRID)%LHCH=>LHCH
      PCGDAT(IGRID)%HCHG=>HCHG
      PCGDAT(IGRID)%LRCHPCG=>LRCHPCG
      PCGDAT(IGRID)%RCHG=>RCHG
      PCGDAT(IGRID)%IT1=>IT1
C
      RETURN
      END