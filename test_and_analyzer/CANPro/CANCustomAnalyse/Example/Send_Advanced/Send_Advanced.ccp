<?xml version="1.0" encoding="gb2312"?>
<Procotol>
  <MessageList>
    <Message Name="Arc" FrameType="标准帧" FrameFormat="数据帧" DataLen="8" CycleTime="0">
      <FlagSugmentList>
        <FlagSugment Name="New_FlagSugment_0" FlagDataPos="帧ID" StartBit="0" DataLen="11" Value="0" />
      </FlagSugmentList>
      <SingleList>
        <Single Name="Sin" StartBit="0" DataLen="8" Factor="1" Offset="0" Minimum="0" Maximun="100" Unit="" StatuValue="" />
        <Single Name="Cos" StartBit="8" DataLen="8" Factor="1" Offset="0" Minimum="0" Maximun="100" Unit="" StatuValue="" />
        <Single Name="HalfSin" StartBit="16" DataLen="8" Factor="1" Offset="0" Minimum="0" Maximun="100" Unit="" StatuValue="" />
      </SingleList>
    </Message>
    <Message Name="Line" FrameType="标准帧" FrameFormat="数据帧" DataLen="8" CycleTime="0">
      <FlagSugmentList>
        <FlagSugment Name="New_FlagSugment_0" FlagDataPos="帧ID" StartBit="0" DataLen="11" Value="1" />
      </FlagSugmentList>
      <SingleList>
        <Single Name="SqureWave" StartBit="0" DataLen="8" Factor="1" Offset="0" Minimum="0" Maximun="100" Unit="" StatuValue="" />
        <Single Name="ObliqueWave" StartBit="8" DataLen="8" Factor="1" Offset="0" Minimum="0" Maximun="100" Unit="" StatuValue="" />
      </SingleList>
    </Message>
  </MessageList>
  <ValueTypeList />
</Procotol>