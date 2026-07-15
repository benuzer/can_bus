<?xml version="1.0" encoding="gb2312"?>
<Procotol>
  <MessageList>
    <Message Name="SquareWave" FrameType="标准帧" FrameFormat="数据帧" DataLen="8" CycleTime="0">
      <FlagSugmentList>
        <FlagSugment Name="New_FlagSugment_0" FlagDataPos="帧ID" StartBit="0" DataLen="11" Value="1" />
      </FlagSugmentList>
      <SingleList>
        <Single Name="DataWave" StartBit="32" DataLen="8" Factor="1" Offset="0" Minimum="0" Maximun="100" Unit="" StatuValue="" />
      </SingleList>
    </Message>
  </MessageList>
  <ValueTypeList />
</Procotol>