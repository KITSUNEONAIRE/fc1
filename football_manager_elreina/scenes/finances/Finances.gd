extends Control

@onready var balance_label: Label = $BalanceLabel
@onready var income_label: Label = $IncomeLabel
@onready var expenses_label: Label = $ExpensesLabel


func _ready() -> void:
_update_finances()


func _update_finances() -> void:
if GameState.club_data.has("finances"):
var finances = GameState.club_data.finances
balance_label.text = "Balance: £%d" % finances.get("balance", 0)
income_label.text = "Weekly Income: £%d" % finances.get("weekly_income", 0)
expenses_label.text = "Weekly Expenses: £%d" % finances.get("weekly_expenses", 0)
else:
balance_label.text = "Balance: £0"
income_label.text = "Weekly Income: £0"
expenses_label.text = "Weekly Expenses: £0"


func _on_back_pressed() -> void:
var err = get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
if err != OK:
print("Error loading dashboard: ", err)
