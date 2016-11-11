
 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"


      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/status
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/CLKA
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/ADDRA
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/DINA
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/WEA
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/ENA
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/RSTB
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/CLKB
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/ADDRB
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/ENB
      waveform add -signals /bram_sdp_1024d_16wr_16rd_tb/bram_sdp_1024d_16wr_16rd_synth_inst/bmg_port/DOUTB
console submit -using simulator -wait no "run"
