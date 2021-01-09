#! /bin/bash
if [ $# != 4 ]; then
  echo "too few args"
  exit 1
fi

declare -A MAP
MAP[0]=A
MAP[1]=B
MAP[2]=C
MAP[3]=D
MAP[4]=E
MAP[5]=F
MAP[6]=G
MAP[7]=H
MAP[8]=I
MAP[9]=J
MAP[10]=K

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
NS3DIR=$DIR/ns-3/
cd $DIR > /dev/null

for i in $(seq $1 $2); do
  for j in $(seq $3 $4); do
        if [ $i != $j ]; then
          mkdir -p "./results/${i}-${j}-init/od_data"
          mkdir -p "./results/${i}-${j}-after/od_data"
          mkdir -p "./results/${i}-${j}-last/od_data"

          # 初期シミュレーション作成
          python3 ./python/create_sim.py --OrigNode ${MAP[$i]} --DestNode ${MAP[$j]} --Opt init > created
          python3 ./python/combine.py
          # 初期シミュレーション実行
          cd $NS3DIR > /dev/null
          ./waf --cwd="../results/${i}-${j}-init" --run "created --OrigNode=${i} --DestNode=${j}"
          # ODトラヒック集計 OD推定
          cd $DIR > /dev/null
          python3 ./python/estimate_od_data.py --Situ init --dataDir "./results/${i}-${j}-init/"
          # クリーンアップ
          rm ./created
          mv ./python/orig_route.py ./results/$i-$j-init
          rm $NS3DIR/scratch/created.cc

          # 経路制御シミュレーション作成
          python3 ./python/create_sim.py --OrigNode ${MAP[$i]} --DestNode ${MAP[$j]} --Opt te > created
          python3 ./python/combine.py
          # 経路制御シミュレーション実行
          cd $NS3DIR > /dev/null
          ./waf --cwd="../results/${i}-${j}-after" --run "created --OrigNode=${i} --DestNode=${j}"
          # ODトラヒック集計 OD推定
          cd $DIR > /dev/null
          python3 ./python/estimate_od_data.py --Situ after --dataDir "./results/${i}-${j}-init/"
          # クリーンアップ
          mv ./python/util_opt_route.py ./results/$i-$j-after
          rm ./created
          rm $NS3DIR/scratch/created.cc

          # 帯域設計経路制御シミュレーション作成
          python3 ./python/create_sim.py --OrigNode ${MAP[$i]} --DestNode ${MAP[$j]} --Opt tecp > created
          python3 ./python/combine.py
          # 帯域設計経路制御シミュレーション実行
          cd $NS3DIR > /dev/null
          ./waf --cwd="../results/${i}-${j}-last" --run "created --OrigNode=${i} --DestNode=${j}"
          # ODトラヒック集計 OD直接計測
          cd $DIR > /dev/null
          python3 ./python/get_od_data.py --Situ last --dataDir "./results/${i}-${j}-last/"
          # クリーンアップ
          mv ./python/util_capa_opt_route.py ./results/$i-$j-last
          mv ./python/capas_incd.py ./results/$i-$j-last
          mv ./python/od_data_init.py ./results/$i-$j-init
          mv ./python/od_data_after.py ./results/$i-$j-after
          mv ./python/od_data_last.py ./results/$i-$j-last
          mv ./estimated_gamma.txt ./results/$i-$j-last
          rm ./created
          rm $NS3DIR/scratch/created.cc
        fi
    done
done
