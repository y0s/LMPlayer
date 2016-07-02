// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import fl.video.FLVPlayback;
	import CueItem;
	import EffectItem;

	/**
	 * エフェクト制御クラス
	 */
	public class EffectControl
	{
		/** エフェクトの種類(矢印) */
		public static const EFFECT_TYPE_ARROW:String = "Arrow";
		/** エフェクトの種類(円) */
		public static const EFFECT_TYPE_CIRCLE:String = "Circle";
		/** エフェクトの種類(画像) */
		public static const EFFECT_TYPE_IMG:String = "Picture";
		
		/**
		 * 円･矢印のエフェクトのスケールが1となる単位サイズは、映像の縦の長さの UNIT_SCALE 倍とする。
		 */
		const UNIT_SCALE:Number = 0.2;
		/**
		 * 画像エフェクトは映像の縦の長さが VIDEO_HEIGHT_FOR_FULL_SCALE_IMG のときにスケール1.0で等倍となることとする。
		 */
		const VIDEO_HEIGHT_FOR_FULL_SCALE_IMG:Number = 360;
		/** スケール設定のための単位長さ(映像の縦の長さ) */
		protected var unitLength:Number;
		/** エフェクトデータ保持配列(4エフェクト×3映像) */
		protected var effectArray:Vector.<Vector.<Vector.<EffectItem>>>;
		/**
		 * 表示エフェクトを映像1～3・エフェクトA～Dに分けて保持し、選択映像と表示設定の状態に応じて表示・非表示を切り替えるムービークリップ配列。
		 */
		protected var effectMcArray:Vector.<Vector.<MovieClip>>;
		/** setup() で外部より与えられ、 effectMcArray の要素を子として持たせるエフェクト表示領域 */
		protected var effectDisplayMC:MovieClip;
		/** effectDisplayMC と重ねられるプレイヤー */
		protected var basePlayer:FLVPlayback;
		/** 映像番号 */
		protected var chSw:int = 0;
		/** 表示切り替えフラグ */
		protected var effSw:Vector.<Vector.<Boolean>>;

		/**
		 * 映像の切替に合わせて effectMcArray の表示状態を更新する.
		 * 
		 * <p>切替前の映像のエフェクトを非表示にし、切替後の映像のエフェクトの表示On/Off状態を表示に反映させる。
		 * force が true の場合は、映像が切り替えられていなくても表示を更新する。</p>
		 * 
		 * @param	ch		切替先映像番号
		 * @param	force	強制表示更新フラグ
		 */
		public function swDisp(ch:int, force:Boolean=false):void
		{
			var i:int;
			
			if ((ch == chSw) && !force) {
				return;
			}
			for (i = 0; i < effectMcArray[chSw].length; ++i) {
				effectMcArray[chSw][i].visible = false;
				effectMcArray[ch][i].visible = effSw[ch][i];
			}
			chSw = ch;
			unitLength = basePlayer.getVideoPlayer(ch).height;
		}
		
		/**
		 * 表示On/Off状態の設定.
		 * 
		 * @param	ch			映像番号
		 * @param	effno		エフェクト番号
		 * @param	dispmode	表示・非表示設定(true で表示)
		 */
		public function setDispMode(ch:int, effno:int, dispmode:Boolean):void
		{
			effSw[ch][effno] = dispmode;
			if (chSw == ch) {
				effectMcArray[ch][effno].visible = dispmode;
			}
		}

		/**
		 * 表示On/Off状態の取得.
		 * 
		 * @param	ch		映像番号
		 * @param	effno	エフェクト番号
		 * @return	true: 表示 / false: 非表示
		 */
		public function getDispMode(ch:int, effno:int):Boolean
		{
			return effSw[ch][effno];
		}
		
		/**
		 * 指定した時刻の表示状態に更新する。
		 * 
		 * @param	time	再生時刻
		 */
		public function updateView(time:Number):void
		{
			var i:int
			var j:int;
			
			for (i = 0; i < effectArray[chSw].length; ++i) {
				if (!effSw[chSw][i]) {
					continue;
				}
				for (j = 0; j < effectArray[chSw][i].length; ++j) {
					with (effectArray[chSw][i][j]) {
						if (effectSymbol.visible) {
							if ((time < sttime) || (time > edtime)) {
								effectSymbol.visible = false;
							}
						} else {
							if ((time >= sttime) && (time <= edtime)) {
								if (efftype == EFFECT_TYPE_IMG) {
									effectSymbol.scaleY = cueArr[0].scaleY * unitLength / VIDEO_HEIGHT_FOR_FULL_SCALE_IMG;
								} else {
									effectSymbol.scaleY = (cueArr[0].scaleY * unitLength * UNIT_SCALE) / effectSymbol.originalHeight;
								}
								effectSymbol.scaleX = effectSymbol.scaleY * cueArr[0].scaleX / cueArr[0].scaleY;
								effectSymbol.x = cueArr[0].x * unitLength;
								effectSymbol.y = cueArr[0].y * unitLength;
								effectSymbol.rotation = cueArr[0].angle;
								effectSymbol.visible = true;
							}
						}
					}
				}
			}
		}
		
		/**
		 * 初期化.
		 * 
		 * <p>映像1～3・エフェクトA～Dそれぞれに対応するムービークリップを effectMcArray に生成して
		 * dispmc　に addChild() し、 arr　内の個別の要素が保持するムービークリップを
		 * effectMcArray　の対応する要素へ addChild() する。</p>
		 * 
		 * @param	arr			映像1～3・エフェクトA～Dのエフェクトデータの配列
		 * @param	swArr		映像1～3・エフェクトA～Dの表示の初期状態の配列
		 * @param	dispmc		エフェクト表示領域用ムービークリップ
		 * @param	player		映像表示プレイヤー
		 */
		public function setup(arr:Vector.<Vector.<Vector.<EffectItem>>>, swArr:Vector.<Vector.<Boolean>>, dispmc:MovieClip, player:FLVPlayback):void
		{
			var i:int;
			var j:int;
			var k:int;
			basePlayer = player;
			unitLength = basePlayer.height;
			effectDisplayMC = dispmc;
			effectArray = arr;
			effectMcArray = new Vector.<Vector.<MovieClip>>(arr.length);
			effSw = new Vector.<Vector.<Boolean>>(swArr.length);
			for (i = 0; i < effectArray.length; ++i) {
				effSw[i] = new Vector.<Boolean>(swArr[0].length);
				effectMcArray[i] = new Vector.<MovieClip>(effectArray[0].length);
				for (j = 0; j < effectArray[i].length; ++j) {
					effectMcArray[i][j] = new MovieClip();
					effectDisplayMC.addChild(effectMcArray[i][j]);
					effectMcArray[i][j].visible = false;
					effSw[i][j] = swArr[i][j];
					for (k = 0; k < effectArray[i][j].length; ++k) {
						effectMcArray[i][j].addChild(effectArray[i][j][k].effectSymbol);
						effectArray[i][j][k].effectSymbol.visible = false;
					}
				}
			}
		}
		
		/**
		 * コンストラクタ.
		 */
		public function EffectControl()
		{
		}
	}
}