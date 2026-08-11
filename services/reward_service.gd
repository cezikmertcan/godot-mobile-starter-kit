extends Node

signal reward_granted(transaction_id: String, amount: int, source: String)


func grant_once(transaction_id: String, amount: int, source: String) -> bool:
	if transaction_id.is_empty() or amount <= 0:
		return false
	if SaveService.has_claimed_reward(transaction_id):
		return false
	SaveService.mark_reward_claimed(transaction_id)
	SoftCurrencyService.grant(amount, source)
	reward_granted.emit(transaction_id, amount, source)
	return true
