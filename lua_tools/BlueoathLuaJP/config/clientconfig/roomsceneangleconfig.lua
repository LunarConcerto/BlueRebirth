return {
  modelAnimConfig = {
    {
      startAngle = 0,
      endAngle = 60,
      animNames = {
        "click1",
        "click2",
        "click3"
      }
    },
    {
      startAngle = 60,
      endAngle = 300,
      animNames = {"turn"}
    },
    {
      startAngle = 300,
      endAngle = 360,
      animNames = {
        "click1",
        "click2",
        "click3"
      }
    }
  },
  modelSpecialAnimConfig = {
    [0] = {
      AngleRange = {
        {startAngle = 0, endAngle = 60},
        {startAngle = 300, endAngle = 360}
      },
      animName = "click_sp"
    }
  }
}
