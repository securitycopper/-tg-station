
#define LIST_ADDLAST(list,element) list.Insert(list.len+1 ,element)


//The PowerNode didn't have power, now it is on.
#define POWER_EVENT_ON 1
//The power node was on but now the power changed.
//The machine needs to determine how it is affected by the power change.
#define POWER_EVENT_POWER_CHANGED 2
//The machine had power other then 0 and now is set to 0
#define POWER_EVENT_OFF 3

#define POWER_TYPE_PRODUCER 1
#define POWER_TYPE_CONSUMER 2

#define POWER_STATE_OFF 0