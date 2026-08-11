extends Node

signal balance_changed(balance: int, delta: int, source: String)


func get_balance() -> int:
	return SaveService.get_currency_balance()


func grant(amount: int, source: String = "") -> int:
	if amount <= 0:
		return get_balance()
	var next_balance := get_balance() + amount
	SaveService.set_currency_balance(next_balance)
	balance_changed.emit(next_balance, amount, source)
	return next_balance


func spend(amount: int, source: String = "") -> bool:
	if amount <= 0 or amount > get_balance():
		return false
	var next_balance := get_balance() - amount
	SaveService.set_currency_balance(next_balance)
	balance_changed.emit(next_balance, -amount, source)
	return true
