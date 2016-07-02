// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	/**
	 * しおりリストアイテム.
	 * 
	 * <p>シーン情報表示部のしおりリスト･しおりクリッカブルマップが保持するしおりアイテム。</p>
	 */
	public class BookmarkItem
	{
		/** id */
		public var id:String = "";
		/** 表示開始時刻 */
		public var sttime:Number = 0;
		/** 表示終了時刻 */
		public var edtime:Number = 0;
		/** お気に入りかどうか */
		public var isFav:Boolean = false;

		/**
		 * コンストラクタ
		 */
		public function BookmarkItem()
		{
		}
	}
}
