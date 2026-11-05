module types

import math.big
import time

pub interface NumberProvider {
	to_number() !f64
}

pub interface BigintProvider {
	to_bigint() !big.Integer
}

pub interface DateProvider {
	to_date() !time.Time
}

pub interface StringProvider {
	to_string() !string
}

pub interface BooleanProvider {
	to_boolean() !bool
}
