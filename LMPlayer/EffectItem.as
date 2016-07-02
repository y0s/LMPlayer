// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import CueItem;

	/**
	 * エフェクトアイテム
	 */
	public class EffectItem
	{
		/** id(現在は利用していない) */
		public var id:String = "";
		/** 表示開始時間 */
		public var sttime:Number = 0;
		/** 表示終了時間 */
		public var edtime:Number = 0;
		/** エフェクトの種類 */
		public var efftype:String = "";
		/** エフェクト画像のパス */
		public var imagepath:String = "";
		/** エフェクトとして表示するムービークリップ。表示サイズの制御用にプロパティ <code>originalHeight</code> に本来の高さを設定すること。 */
		public var effectSymbol: MovieClip;
		/**
		 * 表示タイミングの配列.
		 * 
		 * <p>現状は最初の要素の時間を表示開始時間に、最後の要素の時間を表示終了時間にしているだけだが、
		 * 将来的に動きを持たせられるように配列として保持する。</p>
		 */
		public var cueArr: Vector.<CueItem> = new Vector.<CueItem>();

		/**
		 * コンストラクタ.
		 */
		public function EffectItem()
		{
		}
	}
}