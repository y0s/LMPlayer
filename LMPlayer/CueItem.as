// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	/**
	 * エフェクト動作指定データ
	 */
	public class CueItem
	{
		/** 時刻 */
		public var time: Number = 0;
		/** 表示位置x座標 */
		public var x:Number = 0;
		/** 表示位置y座標 */
		public var y:Number = 0;
		/** 表示角度 */
		public var angle:Number = 0;
		/** x方向倍率 */
		public var scaleX:Number = 1;
		/** y方向倍率 */
		public var scaleY:Number = 1;

		/**
		 * コンストラクタ
		 */
		public function CueItem()
		{
		}
	}
}