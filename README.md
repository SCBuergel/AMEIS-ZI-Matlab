# AMEIS-ZI-Matlab
This Matlab library is intendend for analyzing electrical impedance data recorded from a Zurich Instruments HF2 using the AMEIS architecture developed in the Bio Engineering Laboratory at ETH Zurich, Switzerland (http://www.bsse.ethz.ch/bel/).

Examples can be found in the examples folder of the non-master branches. The basic setup works as follows:
```
ah = initAmeis(directoryToZibinFiles, peakThreshold);
peakData = processFolders(ah);
```
```peakData``` contains the extracted and summarized signal peak and basline information.
