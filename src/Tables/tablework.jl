#add columns after @addaftercolumn so every rows should have @musttobe+1 column
#EXAMPLE CALL -> makesamecolumn(13,-3,"perryHeatCapLiquids_Table2_153.table")
#EXAMPLE CALL -> makesamecolumn(12,-3,"perryHeatsofVaporization_Table2-150.table")
#EXAMPLE CALL -> makesamecolumn(13,-3,"perryLiqidThermalConductivity_Table2-315.table")
#EXAMPLE CALL -> makesamecolumn(13,-3,"perryLiquidViscosity_Table2-313.table")
#EXAMPLE CALL -> makesamecolumn(12,-3,"perryVaporViscosity_Table2-312.table")
#EXAMPLE CALL -> makesamecolumn(12,-3,"perryVaporThermalConductivity_Table2-314.table")
using Roots
function makesamecolumn(musttobe::Int,addaftercolumn::Int,tablename::AbstractString)
  srmin=open(tablename,"r")
  srmout=open(tablename*"_","w")
  count=0
  pos=position(srmin)
  semitoadd=0
  addfrom=0
  pause=false
  lastline=""
  while (!eof(srmin))
    c=read(srmin,Char)
    lastline*=string(c)
    if c=='\n'
      if (count<musttobe && count>7)
        seek(srmin,pos)
        semitoadd=musttobe-count
        addfrom=count+addaftercolumn
      else
        semitoadd=0
        addfrom=0
        write(srmout,lastline)
      end
      count=0
      pos=position(srmin)
      lastline=""
    end
    if (c==';')
      count+=1
    end
    if (semitoadd>0 && addfrom == count)
      while(semitoadd>0)
        semitoadd-=1
        lastline*=";"
        count+=1
      end
      addfrom=0
    end
  end
  close(srmin)
  close(srmout)
end

function checkalltablesprofile()
  tables=["perryCriticals_Table2_141","perryLiquidsVaporPressure_Table2_8","perryHeatsofVaporization_Table2_150","perryHeatCapLiquids_Table2_153","perryHeatCapIdealGas_Table2_155","perryHeatCapIdealGas_Table2_156","perryEnergiesOfFormation_Table2_179","perryVaporViscosity_Table2_312","perryLiquidViscosity_Table2_313","perryVaporThermalConductivity_Table2_314","perryLiqidThermalConductivity_Table2_315"]
  i=1
  glob=Array(Any,11)
  for (t in tables)
    file=open(t*".table");
    glob[i]=readdlm(file,';',header=false);
    println(t*" is loaded")
    close(file)
    i+=1
  end
  for (i in 2:11)
    jj=1
    j=1
    while (j < size(glob[i])[1])
      glob[i][j,1]=int(glob[i][j,1])
      try
        while (glob[i][j,[1,2,3,4]]!=glob[1][jj,[1,2,3,4]])
          jj+=1
        end
      catch   err
        @assert false "$(glob[i][j,[1,2,3,4]]) in $(tables[i])"
      end
      j+=1
    end
    println(tables[i]*" Done $j elements found")
  end
end
c=Vector{Float64}(5)
function boilingpoint()
  global c
  global vps
  tables=["perryFormulaCompounds","perryLiquidsVaporPressure_Table2_8"]
  file=open(tables[2]*".table","r");
  vps=readdlm(file,';',header=false);
  close(file)
  file=open(tables[1]*"_.table","w");
  for (i=1:size(vps)[1])
    c=vps[i,3:7]
    bp=fzeros(vp,vps[i,8],vps[i,10])
    if (length(bp)==0)
      bp=NaN
    else
      if (length(bp)==1)
        bp=bp[1]
      end
    end
    write(file,string(bp))
    write(file,'\n')
  end
  close(file)
end
function vp(t::Float64)
  global c
  return exp(c[1] + c[2]/t + c[3]*log(t) + c[4]*t^c[5])-101325
end
function checkYAWS()
  file=open("YAWS_Table"*".table","r");
  yws=readdlm(file,';',header=false);
  close(file);
  println(size(yws))
  typevals=nothing
  for (i=1:size(yws)[1])
    (yws[i,end]!="") && println(yws[i,1])
  end
end
function checkYAWS2()
  file=open("YAWS2_Table"*".table","r");
  yws=readdlm(file,';',header=false);
  close(file);
  println(size(yws))
  typevals=nothing
  for (i=1:size(yws)[1])
    (yws[i,end]!="") && println(yws[i,1])
  end
end
function readwritematchbp()
  file=open("YAWS2_Table"*".table","r");
  yws2=readdlm(file,';',header=false);
  close(file);
  file=open("YAWS_Table"*".table","r");
  yws=readdlm(file,';',header=false);
  close(file);
  file=open("perryFormulaCompounds"*".table","r");
  prry=readdlm(file,';',header=false);
  close(file);
  file=open("bpYAWS_.table","w");
  for (j in 1:size(prry)[1])
    i=1
    while(i<size(yws)[1] && yws[i,5]!=prry[j,4])
      i+=1
    end
    if (i < size(yws)[1] && yws[i,5]==prry[j,4])
      write(file,string(prry[j,1])*";"*prry[j,4]*";"*string(yws[i,7]))
      write(file,'\n')
    else #search next chapter
      ii=1
      while(ii<size(yws2)[1] && yws2[ii,4]!=prry[j,4])
        ii+=1
      end
      if (ii < size(yws2)[1] && yws2[ii,4]==prry[j,4])
        write(file,string(prry[j,1])*";"*prry[j,4]*";"*string(yws2[ii,8]))
        write(file,'\n')
      else
        write(file,'\n')
        println(prry[j,:])
      end
    end
  end
  close(file)
end
function hv(c::Array{Any,2}, tr::Float64)
  return c[1]*1e7*((1 -tr)^(c[2]+c[3]*tr+c[4]*tr^2))
end
function readbpwriteheatofvaporizationatbp()
  file=open("perryFormulaCompounds"*".table","r");
  bp=readdlm(file,';',header=false);
  close(file)
  file=open("perryHeatsofVaporization_Table2_150"*".table","r");
  hev=readdlm(file,';',header=false);
  close(file)
  file=open("perryCriticals_Table2_141"*".table","r");
  cr=readdlm(file,';',header=false);
  close(file)
  file=open("HoVatBP_"*".table","w");
  i=1
  println(size(hev))
  while(i<=size(cr)[1])
    tcri=cr[i,3]
    bopo=bp[i,6]
    hovbp=hv(hev[i,3:6],bopo/tcri)
    write(file,";"*string(hovbp))
    write(file,'\n')
    i+=1
  end
  close(file)
end
function liquidDensityAt25C()
  file=open("perryDensities_Table2_32"*".table","r");
  ld=readdlm(file,';',header=false);
  close(file)
  i=1
  while(i<=size(ld)[1])
    c=ld[i,:]
    lid(c[3:end], 273.15 + 25, round(Int,c[1]))
    i+=1;
  end
end

#Liquid dencity
function lid(c::Vector{Float64}, t::Float64, compId::Int)
  if (t>c[5] && t<c[7])
    if (compId==342 || compId==318)
      return c[1]+c[2]*t+c[3]*t^2+c[4]*t^3 # o-terphenyl and water limited range
    end
    if (compId==342) # For water over the entire temperature range of 273.16 to 647.096 K.
      ta=1-(t/647.096)
      return 17.863+58.606*ta^0.35 - 95.396*ta^(2/3)+213.89*ta- 141.26*ta^(4/3)
    end
    return c[1]/(c[2]^(1+(1-t/c[3])^c[4]))  # The others
  else
    println(compId)
    return NaN
  end
end
