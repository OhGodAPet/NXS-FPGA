IVL			= iverilog
IVLFLAGS	= -g 2005-sv
all: NexusHash_tb NexusTransform_tb NexusTransform_NewKeccak_tb NexusTransform_ExpKeccak_tb

NexusHash_tb: ../NexusKeccak.v ../SkeinRounds.v ../NexusSkein.v NexusHash_tb.v
	$(IVL) $(IVLFLAGS) ../NexusKeccak.v ../SkeinRounds.v ../NexusSkein.v NexusHash_tb.v -o NexusHash_tb
	
NexusTransform_tb: ../NexusKeccak.v ../SkeinRounds.v ../NexusSkein.v ../NexusTransform.v NexusTransform_tb.v
	$(IVL) $(IVLFLAGS) ../NexusKeccak.v ../SkeinRounds.v ../NexusSkein.v ../NexusTransform.v NexusTransform_tb.v -o NexusTransform_tb

#NexusTransform_NewKeccak_tb: ../NexusKeccak2.v ../SkeinRounds.v ../NexusSkein.v ../NexusTransform.v NexusTransform_tb.v
#	$(IVL) $(IVLFLAGS) ../NexusKeccak2.v ../SkeinRounds.v ../NexusSkein.v ../NexusTransform.v NexusTransform_tb.v -o NexusTransform_NewKeccak_tb

#NexusTransform_ExpKeccak_tb: ../NexusKeccak3.v ../SkeinRounds.v ../NexusSkein.v ../NexusTransform.v NexusTransform_tb.v
#	$(IVL) $(IVLFLAGS) ../NexusKeccak3.v ../SkeinRounds.v ../NexusSkein.v ../NexusTransform.v NexusTransform_tb.v -o NexusTransform_ExpKeccak_tb
