// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import fl.controls.RadioButtonGroup;
	import flash.display.*;
	import flash.text.*;
	import CaptionItem;

	/**
	 * 字幕表示部クラス.
	 * 
	 * <p>字幕表示用のテキストフィールド2個と、それぞれの字幕データ配列を持つ。</p>
	 * <p>字幕データ配列は、時間0から再生終了時間までの連続した時間を区切るデータを <code>CaptionItem</code> 型の要素として持ち、
	 * 再生時間に対応する要素の <code>captionText</code> を表示に反映させる。</p>
	 * 
	 * @see CaptionItem
	 */
	public class DualCaption extends MovieClip
	{
		/** 字幕1 */
		public var caption1:TextField;
		/** 字幕2 */
		public var caption2:TextField;
		/** 字幕1 ON/OFFボタン */
		public var bCap1:ToggleButtonBase;
		/** 字幕2 ON/OFFボタン */
		public var bCap2:ToggleButtonBase;
		
		/** 字幕の個数 */
		const CAPTION_COUNT:int = 2;
		/** 字幕データの時間間隔の最小単位 */
		const TIME_FRACTION:Number = 0.001;
		/** 字幕の書式設定用HTMLタグ(開き側) */
		const OPEN_TAG:String = "<b>";
		/** 字幕の書式設定用HTMLタグ(閉じ側) */
		const CLOSE_TAG:String = "</b>";
		
		private static const htmlEntity:Array = [["&", "&amp;"], ["<", "&lt;"], [">", "&gt;"], ['"', "&quot;"], ["'", "&apos;"]];
		
		/**
		 * 字幕データ.
		 * 
		 * <p>字幕XMLファイルは字幕が表示される部分のみを記述するが、このデータは映像の先頭から終端まで表示の無い部分も含めてデータを保持する。</p>
		 */
		protected var captionDataArr:Vector.<Vector.<CaptionItem>> = new Vector.<Vector.<CaptionItem>>(CAPTION_COUNT);
		/** 字幕表示部配列 */
		protected var captionFieldArr:Vector.<TextField> = new Vector.<TextField>(CAPTION_COUNT);
		/** 表示・非表示フラグ */
		protected var showSwArr:Vector.<Boolean> = new Vector.<Boolean>(CAPTION_COUNT);
		/** 字幕データの現在の位置を示す */
		protected var indexArr:Vector.<int> = new Vector.<int>(CAPTION_COUNT);
		/** 字幕の表示先 */
		protected var dispDestination:MovieClip;
		
		/**
		 * 字幕データを初期化する.
		 * 
		 * <p>字幕データを、映像の先頭から終端まで字幕が無い状態に初期化する。</p>
		 * 
		 * @param	arr	初期化対象字幕データ
		 */
		protected function initCcaptionArray(arr:Vector.<CaptionItem>):void
		{
			while(arr.length > 1) {
				arr.pop();
			}
			arr[0].sttime = 0;
			arr[0].edtime = Number.MAX_VALUE;
			arr[0].id = "";
			arr[0].captionText = "";
		}
		
		/**
		 * 字幕データに字幕を追加.
		 * 
		 * <p>追加する字幕に対応する位置で字幕データを区切り、表示内容を設定する。</p>
		 * 
		 * @param	arr		追加対象字幕データ
		 * @param	item	追加する字幕
		 */
		protected function addCaptionItem(arr:Vector.<CaptionItem>, item:CaptionItem):void
		{
			for (var i:int = arr.length - 1; i >= 0; --i) {
				if ((arr[i].sttime <= item.sttime) && (item.sttime <= arr[i].edtime)) {
					if ((item.sttime - arr[i].sttime) < TIME_FRACTION) {
						//開始時間が一致
						if ((arr[i].edtime - item.edtime) < TIME_FRACTION) {
							//終了時間も一致する場合は上書き
							arr[i].captionText = item.captionText;
							arr[i].fontSize = item.fontSize;
						} else {
							//終了時間が一致しない場合は、領域を2分割し前側に割り当て
							arr.splice(i, 0, new CaptionItem());
							arr[i].sttime = arr[i + 1].sttime;
							arr[i].edtime = item.edtime;
							arr[i + 1].sttime = item.edtime;
							arr[i].id = item.id;
							arr[i].captionText = item.captionText;
							arr[i].fontSize = item.fontSize;
						}
					} else {
						//開始時間が一致しない
						if ((arr[i].edtime - item.edtime) < TIME_FRACTION) {
							//終了時間が一致する場合は、領域を2分割し後ろ側に割り当て
							arr.splice(i + 1, 0, new CaptionItem());
							arr[i + 1].edtime = arr[i].edtime;
							arr[i + 1].sttime = item.sttime;
							arr[i].edtime = item.sttime;
							arr[i + 1].id = item.id;
							arr[i + 1].captionText = item.captionText;
							arr[i + 1].fontSize = item.fontSize;
						} else {
							//終了時間が一致しない場合は、領域を3分割し真ん中に割り当て
							arr.splice(i + 1, 0, new CaptionItem(), new CaptionItem());
							arr[i + 1].sttime = item.sttime;
							arr[i + 1].edtime = item.edtime;
							arr[i + 1].id = item.id;
							arr[i + 1].captionText = item.captionText;
							arr[i + 1].fontSize = item.fontSize;
							arr[i + 2].edtime = arr[i].edtime;
							arr[i + 2].sttime = item.edtime;
							arr[i + 2].id = arr[i].id;
							arr[i + 2].captionText = arr[i].captionText;
							arr[i + 2].fontSize = arr[i].fontSize;
							arr[i].edtime = item.sttime;
						}
					}
					break;
				}
			}
		}
		
		/**
		 * 字幕データを初期化し、引数で与えられたデータを取り込む。
		 * 
		 * @param	idx		字幕1or2選択
		 * @param	data	設定する字幕データ
		 */
		public function setCaptionData(idx:int, data:Vector.<CaptionItem>):void
		{
			initCcaptionArray(captionDataArr[idx]);
			for (var i:int = 0; i < data.length; ++i) {
				addCaptionItem(captionDataArr[idx], data[i]);
			}
		}
		
		/**
		 * 字幕表示切り替え.
		 * 
		 * <p>表示・非表示の切替のみ行っているので、 <code>updateCaption()</code> を
		 * <code>force</code> を <code>true</code> にしてコールして表示内容を更新すること。</p>
		 * 
		 * @param	sw1	字幕1表示on/off
		 * @param	sw2	字幕2表示on/off
		 */
		public function captionDispSw(sw1:Boolean, sw2:Boolean):void
		{
			showSwArr[0] = sw1;
			showSwArr[1] = sw2;
			
			for (var i:int = 0; i < CAPTION_COUNT; ++i) {
				captionFieldArr[i].visible = showSwArr[i];
			}
		}
		
		/**
		 * １つの字幕の表示を切り替える.
		 * 
		 * @param	capNo	字幕番号(字幕1が0)
		 * @param	sw		対象字幕のon/off
		 */
		public function captionDispSwSingle(capNo:uint, sw:Boolean):void
		{
			showSwArr[capNo] = sw;
			captionFieldArr[capNo].visible = sw;
		}
		
		private function replaceStr(source_str:String, find_str:String, replace_str:String):String
		{
			var numChar:uint = find_str.length;
			var end:int;
			var result_str:String = "";
			for (var i:uint = 0; -1 < (end = source_str.indexOf(find_str, i)); i = end + numChar) {
				result_str +=  source_str.substring(i, end) + replace_str;
			}
			result_str +=  source_str.substring(i);
			return result_str;
		}
		
		/**
		 * 字幕表示状態の更新.
		 * 
		 * <p>各字幕データの現在位置を更新し、現在位置が変化したか、あるいは強制更新フラグが true の場合に表示内容を更新する。</p>
		 * <p>非表示状態のテキストフィールドは更新していないので、表示状態を切り替えたときは
		 * <code>force</code> を <code>true</code> にしてコールすること。</p>
		 * 
		 * @param	time	現在時間
		 * @param	force	強制更新フラグ
		 */
		public function updateCaption(time:Number, force:Boolean = false): void
		{
			var possave:int;
			var escapedStr:String;
			var fontTag1:String = "";
			var fontTag2:String = "";
			
			for (var i:int = 0; i < CAPTION_COUNT; ++i) {
				possave = indexArr[i];
				while (captionDataArr[i][indexArr[i]].sttime > time) {
					--indexArr[i];
				}
				while (captionDataArr[i][indexArr[i]].edtime < time) {
					++indexArr[i];
				}
				if (captionFieldArr[i].visible && ((possave != indexArr[i]) || force)) {
					//"<"などをHTMLエンティティに変換
					escapedStr = captionDataArr[i][indexArr[i]].captionText;
					for (var j:int = 0; j < htmlEntity.length;++j) {
						escapedStr = replaceStr(escapedStr, htmlEntity[j][0], htmlEntity[j][1]);
					}
					if (captionDataArr[i][indexArr[i]].fontSize != CaptionItem.DEFAULT_FONT_SIZE) {
						fontTag1 = "<font size='";
						if (captionDataArr[i][indexArr[i]].fontSize > CaptionItem.DEFAULT_FONT_SIZE) {
							fontTag1 += "+";
						}
						fontTag1 += Math.round((captionDataArr[i][indexArr[i]].fontSize - CaptionItem.DEFAULT_FONT_SIZE) * Number(captionFieldArr[i].defaultTextFormat.size) / CaptionItem.DEFAULT_FONT_SIZE).toString();
						//fontTag1 += (captionDataArr[i][indexArr[i]].fontSize - CaptionItem.DEFAULT_FONT_SIZE).toString();
						fontTag1 += "'>";
						fontTag2 = "</font>";
					} else {
						fontTag1 = "";
						fontTag2 = "";
					}
					captionFieldArr[i].htmlText = OPEN_TAG +fontTag1 + escapedStr +fontTag2 + CLOSE_TAG;
					//captionFieldArr[i].htmlText = OPEN_TAG + captionDataArr[i][indexArr[i]].captionText + CLOSE_TAG;
				}
			}
		}
		
		/**
		 * 字幕の表示先
		 */
		public function set dispTo(dest: MovieClip):void
		{
			dest.caption1.visible = captionFieldArr[0].visible;
			dest.caption2.visible = captionFieldArr[1].visible;
			dispDestination = dest;
			captionFieldArr[0] = dispDestination.caption1;
			captionFieldArr[1] = dispDestination.caption2;
		}
		
		/**
		 * コンストラクタ
		 */
		public function DualCaption()
		{
			dispDestination = this;
			captionFieldArr[0] = caption1;
			captionFieldArr[1] = caption2;
			for (var i:int = 0; i < CAPTION_COUNT; ++i) {
				showSwArr[i] = true;
				captionFieldArr[i].visible = showSwArr[i];
				indexArr[i] = 0;
				captionDataArr[i] = new Vector.<CaptionItem>();
				captionDataArr[i].push(new CaptionItem());
			}
		}
	}
}