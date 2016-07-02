// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	/**
	 * 字幕アイテム
	 */
	public class CaptionItem
	{
		/** id(現在は利用していない) */
		public var id:String = "";
		/** 表示テキスト */
		public var captionText:String = "";
		/** 表示開始時刻 */
		public var sttime:Number = 0;
		/** 表示終了時刻 */
		public var edtime:Number = Number.MAX_VALUE;
		/** デフォルト文字サイズ */
		public static const DEFAULT_FONT_SIZE:Number = 12.0;
		/** 文字サイズ */
		public var fontSize:Number = DEFAULT_FONT_SIZE;

		/**
		 * コンストラクタ
		 */
		public function CaptionItem()
		{
		}
	}
}