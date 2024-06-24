extends Node

@onready var playBtn   = $"../Menu/PlayBtn";
@onready var stepBtn   = $"../Menu/StepBtn";
@onready var resetBtn  = $"../Menu/ResetBtn";
@onready var randomBtn = $"../Menu/RandomBtn";
@onready var cellLabelText = $"../CellCanvas/CellDescription";

const NUM_CELLS_X = 86;
const NUM_CELLS_Y = 86;
const DELTA_TIME = 0.001;
const START_PROBABILITY = 0.2;
var cellSize: Vector2 = Vector2(10.0, 10.0);

var currentWorldIsAlive: Array[bool] = [];
var nextWorldIsAlive: Array[bool] = [];
var worldTime: Array[int] = [];
var worldCell: Array[Node] = [];

var time = 0.0;
var isRunning = false;

var c_w: Color = Color(1.0, 1.0, 1.0);
var c_b: Color = Color(0.1, 0.1, 0.12);

var mpos: Vector2 = Vector2(0.0, 0.0);
var mcellpos: Vector2i = Vector2i(0, 0);

var isMouseInside: bool = false;
func _input(event) :
	if event is InputEventMouseMotion:
		mpos.x = event.position.x - self.position.x;
		mpos.y = event.position.y - self.position.y;
		if (mpos.x < 0 
		or mpos.y < 0 
		or mpos.x > self.size.x + self.position.x 
		or mpos.y > self.size.y + self.position.y) :
			isMouseInside = false;
		else :
			isMouseInside = true;
			
		mcellpos.x = clamp(floor(mpos.x / cellSize.x), 0, NUM_CELLS_X - 1);
		mcellpos.y = clamp(floor(mpos.y / cellSize.y), 0, NUM_CELLS_Y - 1);
		print_cell_info();
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and isMouseInside and event.pressed :
			var i = xy_to_i(mcellpos.x, mcellpos.y);
			if currentWorldIsAlive[i] :
				kill_cell(i, true);
			else :
				born_cell(i, true);
			

func print_cell_info() :
	var i = xy_to_i(mcellpos.x, mcellpos.y);
	var isCellAlive = currentWorldIsAlive[i];
	var aliveText = "ALIVE for {n} steps.".format([["n", worldTime[i]]]) if isCellAlive else "DEAD";
	cellLabelText.text = "Cell:\t\t{posx}, {posy}
	\t\t{alive}
	".format([
		["posx", mcellpos.x], ["posy", mcellpos.y],
		["alive", aliveText]
	])

func _ready():
	var mesh = preload("res://cell.tscn");
		
	playBtn.pressed.connect(play_pressed);
	stepBtn.pressed.connect(step_pressed);
	resetBtn.pressed.connect(reset_pressed);
	randomBtn.pressed.connect(random_pressed);
	
	cellSize = Vector2(
		self.size.x / NUM_CELLS_X,
		self.size.y / NUM_CELLS_Y
	)
	
	for y in range(NUM_CELLS_X) :
		for x in range(NUM_CELLS_X) :
			var i = xy_to_i(x, y);
			worldCell.append(mesh.instantiate());
			worldCell[i].size = cellSize;
			worldCell[i].position = Vector2(
				x * cellSize.x,
				y * cellSize.y
				);
			currentWorldIsAlive.append(false);
			nextWorldIsAlive.append(false);
			worldTime.append(0);
			kill_cell(i);
			add_child(worldCell[i]);

func reset() :
	for y in range(NUM_CELLS_X) :
		for x in range(NUM_CELLS_Y):
			var i = xy_to_i(x, y);
			kill_cell(i);
	
	stop();

func random() :
	var rng = RandomNumberGenerator.new();
	
	for y in range(NUM_CELLS_X) :
		for x in range(NUM_CELLS_X) :
			var i = xy_to_i(x, y);
			if rng.randf_range(0.0, 1.0) < START_PROBABILITY:
				born_cell(i);
			else :
				kill_cell(i);

func xy_to_i(x: int, y: int) :
	return y * NUM_CELLS_X + x;

func kill_cell(i: int, current: bool = true) :
	if current : 
		currentWorldIsAlive[i] = false;
	else :
		nextWorldIsAlive[i] = false;
	worldTime[i] = 0;
	worldCell[i].color = c_b;
	
func born_cell(i: int, current: bool = true) :
	if current : 
		currentWorldIsAlive[i] = true;
	else :
		nextWorldIsAlive[i] = true;
	worldTime[i] = 1;
	worldCell[i].color = c_w;

func _process(delta):
	
	if isRunning :
		time += delta;
		if time >= DELTA_TIME :
			print_cell_info();
			advance_sim();
			time = 0.0;

func compute_neigbours(x: int, y: int) -> int :
	var neighbours = [
		xy_to_i(x - 1, y - 1) if x > 0                 and y > 0                 else -1,
		xy_to_i(x,     y - 1) if                           y > 0                 else -1,
		xy_to_i(x + 1, y - 1) if x < (NUM_CELLS_X - 1) and y > 0                 else -1,
		xy_to_i(x - 1, y)     if x > 0                                           else -1,
		xy_to_i(x + 1, y)     if x < (NUM_CELLS_X - 1)                           else -1,
		xy_to_i(x - 1, y + 1) if x > 0                 and y < (NUM_CELLS_Y - 1) else -1,
		xy_to_i(x,     y + 1) if                           y < (NUM_CELLS_Y - 1) else -1,
		xy_to_i(x + 1, y + 1) if x < (NUM_CELLS_X - 1) and y < (NUM_CELLS_Y - 1) else -1
	];
	
	var n_count = 0;
	for n in neighbours :
		if n > -1 and currentWorldIsAlive[n] :
			n_count += 1;
	
	return n_count;

func advance_sim() :
	var worldAlive = false;
	nextWorldIsAlive = currentWorldIsAlive.duplicate();
	for y in range(NUM_CELLS_Y) :
		for x in range(NUM_CELLS_X) :
			var n_count = compute_neigbours(x, y);
			var i = xy_to_i(x, y);
			
			if nextWorldIsAlive[i] :
				if n_count == 2 or n_count == 3:
					worldTime[i] += 1;
					worldAlive = true;
				else :
					kill_cell(i, false);
			elif n_count == 3 :
				born_cell(i, false);
				worldAlive = true;
	
	currentWorldIsAlive = nextWorldIsAlive;
	if not worldAlive :
		stop();

func play_pressed() :
	if isRunning :
		time = 0;
	isRunning = !isRunning;
	print_play_button();

func play() :
	time = 0;
	isRunning = true;
	print_play_button();
	
func stop():
	isRunning = false;
	print_play_button();

func print_play_button():
	var text = "Pause" if isRunning else "Play";
	playBtn.text = text;

func step_pressed() :
	advance_sim();

func reset_pressed() :
	reset();

func random_pressed() :
	random();
