import time
import os
import re
import json
import numpy as np
import skfuzzy as fuzz
from sklearn.preprocessing import StandardScaler
import pickle

# Константы
RAW_DATA_PATH = r"C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\980034604#1\SavedVariables\PlayersData.lua"
RESULT_FILE_PATH = r"C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\980034604#1\SavedVariables\Recomendations.lua"
MODEL_PATH = "fcm_model.pkl"
CLUSTER_NAMES = ["Achievers", "Socializers", "Killers", "Explorers"]
FEATURE_NAMES = ["Время в подземельях", "PvP убийства", "Сообщения в чате", "Собранные ресурсы"]

# Функция извлечения данных из файла
def extract_data_from_file(file_path):
    if not os.path.exists(file_path):
        print(f"Файл не найден: {file_path}")
        return {"player_data_json": None, "player_exited": None, "coef": 0, "step": 0}
    
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
        
        # Извлечение PlayerDataJSON
        match_json = re.search(r'PlayerDataJSON\s*=\s*"(.*)"', content)
        if match_json:
            json_str = match_json.group(1).encode().decode('unicode_escape')
            print(f"Извлеченная строка JSON: '{json_str}'")
            if json_str.strip():
                try:
                    player_data_json = json.loads(json_str)
                except json.JSONDecodeError as e:
                    print(f"Ошибка парсинга JSON: {e}")
                    player_data_json = None
            else:
                print("PlayerDataJSON пуст.")
                player_data_json = None
        else:
            print("PlayerDataJSON не найден в файле.")
            player_data_json = None
        
        # Извлечение playerExitedGame
        match_exit = re.search(r'playerExitedGame\s*=\s*(true|false)', content, re.IGNORECASE)
        if match_exit:
            player_exited = match_exit.group(1).lower() == 'true'
        else:
            print("playerExitedGame не найден в файле.")
            player_exited = None

        # Извлечение CoeffOfIdentify
        match_coeff = re.search(r'CoeffOfIdentify\s*=\s*(\d+\.?\d*)', content, re.IGNORECASE)
        if match_coeff:
            identify_coeff = float(match_coeff.group(1))
            print(f"Найден CoeffOfIdentify: {identify_coeff}")
        else:
            print("CoeffOfIdentify не найден в файле.")
            identify_coeff = 0

        # Извлечение Step
        stepik = re.search(r'Stepik\s*=\s*(\d+\.?\d*)', content, re.IGNORECASE)
        if stepik:
            step = float(stepik.group(1))
            print("Найден Stepik", step)
        else:
            print("Stepik не найден")
            step = 0
        
        return {"player_data_json": player_data_json, "player_exited": player_exited, "coef": identify_coeff, "step": step}

# Функция установки значения playerExitedGame
def set_player_exited_game(file_path, value):
    if not os.path.exists(file_path):
        print(f"Файл не найден: {file_path}")
        return False
    
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    pattern = r'(playerExitedGame\s*=\s*)(true|false)'
    new_value = str(value).lower()
    for i, line in enumerate(lines):
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            lines[i] = match.group(1) + new_value + '\n'
            with open(file_path, "w", encoding="utf-8") as f:
                f.writelines(lines)
            print(f"playerExitedGame установлен в {value}")
            return True
    print("playerExitedGame не найден в файле.")
    return False

def train_fcm(save_model=True):
    np.random.seed(42)
    n_per_cluster = 50
    mean0 = [480, 10, 150, 100]  # Achievers
    std0 = [100, 3, 150, 30]
    mean1 = [120, 10, 300, 100]  # Socializers
    std1 = [100, 3, 150, 30]
    mean2 = [120, 50, 150, 100]  # Killers
    std2 = [100, 3, 150, 30]
    mean3 = [120, 10, 150, 400]  # Explorers
    std3 = [100, 3, 150, 30]
    
    data0 = np.random.normal(loc=mean0, scale=std0, size=(n_per_cluster, 4))
    data1 = np.random.normal(loc=mean1, scale=std1, size=(n_per_cluster, 4))
    data2 = np.random.normal(loc=mean2, scale=std2, size=(n_per_cluster, 4))
    data3 = np.random.normal(loc=mean3, scale=std3, size=(n_per_cluster, 4))
    
    training_data = np.vstack([data0, data1, data2, data3])
    np.random.shuffle(training_data)
    
    scaler = StandardScaler()
    training_data_scaled = scaler.fit_transform(training_data)
    training_data_scaled_T = training_data_scaled.T
    
    n_clusters = 4
    cntr, u, u0, d, jm, p, fpc = fuzz.cluster.cmeans(
        training_data_scaled_T, 
        c=n_clusters, 
        m=2, 
        error=0.005, 
        maxiter=1000,
        seed=42
    )
    
    centers_unscaled = scaler.inverse_transform(cntr)
    scaler_normalize = StandardScaler()
    centers_normalized = scaler_normalize.fit_transform(centers_unscaled)
    
    dynamic_cluster_names = []
    used_names = set()
    for idx, center in enumerate(centers_normalized):
        max_feature_index = np.argmax(np.abs(center))
        possible_names = {0: "Achievers", 1: "Killers", 2: "Socializers", 3: "Explorers"}
        for name in sorted(possible_names.items(), key=lambda x: (-np.abs(center[x[0]]), x[0])):
            if name[1] not in used_names:
                dynamic_cluster_names.append(name[1])
                used_names.add(name[1])
                break
        else:
            dynamic_cluster_names.append(f"Cluster{idx}")
            used_names.add(f"Cluster{idx}")
        
        print(f"Кластер {idx} ({dynamic_cluster_names[-1]}):")
        for i, (feature, value) in enumerate(zip(FEATURE_NAMES, centers_unscaled[idx])):
            print(f"  {feature}: {value:.1f}")
        print()
    
    if save_model:
        with open(MODEL_PATH, "wb") as f:
            pickle.dump({"scaler": scaler, "cntr": cntr, "n_clusters": n_clusters, "cluster_names": dynamic_cluster_names}, f)
        print(f"Модель сохранена в {MODEL_PATH}")
    return scaler, cntr, n_clusters, dynamic_cluster_names

# Функция загрузки модели
def load_fcm_model():
    try:
        with open(MODEL_PATH, "rb") as f:
            model = pickle.load(f)
        print(f"Модель загружена из {MODEL_PATH}")
        if 'cluster_names' not in model:
            print("Модель не содержит имен кластеров. Обучаем новую модель.")
            return train_fcm(save_model=True)
        return model["scaler"], model["cntr"], model["n_clusters"], model["cluster_names"]
    except FileNotFoundError:
        print("Файл модели не найден. Обучаем новую модель.")
        return train_fcm(save_model=True)

# Функция обработки данных игрока
def process_player_data(raw_json, scaler, cntr, n_clusters, cluster_names):
    try:
        data = raw_json
        player_array = np.array([
            data["time_in_dungeons"], data["Kills"], data["Messages"], data["Stones,Grass,Meals and etc."]
        ], dtype=float).reshape(1, -1)
    except Exception as e:
        print(f"Ошибка обработки данных игрока: {e}")
        return None
    
    print("\nДанные игрока (исходный масштаб):")
    print(player_array)
    
    player_scaled = scaler.transform(player_array)
    player_scaled_T = player_scaled.T
    
    u_player, u0_player, d_player, jm_player, p_player, fpc_player = fuzz.cluster.cmeans_predict(
        player_scaled_T, cntr, m=2, error=0.005, maxiter=1000
    )
    membership_player = u_player.ravel()
    
    # Применяем ограничения 10% и 70%
    membership_player = np.clip(membership_player, 0.10, 0.70)  # Ограничиваем между 0.1 и 0.7
    # Нормализуем, чтобы сумма была равна 1 (100%)
    membership_player = membership_player / membership_player.sum()
    
    print("\nПроцентное отношение принадлежности игрока к кластерам (с ограничениями 10-70%):")
    cluster_data = {}
    for i, mem in enumerate(membership_player):
        cluster_name = cluster_names[i]
        percentage = round(mem * 100, 2)
        print(f"{cluster_name}: {percentage}%")
        cluster_data[cluster_name] = {"percentage": percentage}
    
    dominant_cluster_index = np.argmax(membership_player)
    dominant_cluster = cluster_names[dominant_cluster_index]
    print(f"Доминирующий тип игрока: {dominant_cluster}")
    
    result_data = {"cluster_membership": cluster_data}
    return result_data

# Функция сохранения результата
def save_processed_result(result_data, file_path):
    existing_lines = []
    player_type_data_start = None
    player_type_data_end = None
    player_type_data_nil = None
    
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            existing_lines = f.readlines()
    
    for i, line in enumerate(existing_lines):
        if line.strip().startswith('playerTypeData = {'):
            player_type_data_start = i
        elif player_type_data_start is not None and line.strip() == '}':
            player_type_data_end = i
            break
        elif line.strip() == 'playerTypeData = nil':
            player_type_data_nil = i
    
    indent = "    "
    new_player_type_data = []
    for cluster, details in result_data['cluster_membership'].items():
        new_player_type_data.append(f'{indent}["{cluster}"] = {round(details["percentage"], 2)},\n')
    
    if player_type_data_start is not None and player_type_data_end is not None:
        existing_lines[player_type_data_start+1:player_type_data_end] = new_player_type_data
    elif player_type_data_nil is not None:
        existing_lines[player_type_data_nil:player_type_data_nil+1] = ['playerTypeData = {\n'] + new_player_type_data + ['}\n']
    else:
        if existing_lines and not existing_lines[-1].endswith('\n'):
            existing_lines.append('\n')
        existing_lines.append('playerTypeData = {\n')
        existing_lines.extend(new_player_type_data)
        existing_lines.append('}\n')
    
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.writelines(existing_lines)
        print(f"Данные успешно сохранены в {file_path} в {time.strftime('%H:%M:%S')}")
    except Exception as e:
        print("Ошибка сохранения результата:", e)

# Функция сохранения identifyCoef
def save_identify_coef(file_path, identify_coeff):
    if not os.path.exists(file_path):
        print(f"Файл не найден: {file_path}")
        return False
    
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    pattern = r'(identifyCoef\s*=\s*)(\d+\.?\d*)'
    found = False
    for i, line in enumerate(lines):
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            lines[i] = f'{match.group(1)}{identify_coeff}\n'
            found = True
            break
    
    if not found:
        if lines and not lines[-1].endswith('\n'):
            lines.append('\n')
        lines.append(f'identifyCoef = {identify_coeff}\n')
    
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"identifyCoef установлен в {identify_coeff} в файле {file_path}")
        return True
    except Exception as e:
        print("Ошибка сохранения identifyCoef:", e)
        return False
    
# Функция установки Step в 1
def set_stepik(file_path):
    if not os.path.exists(file_path):
        print(f"Файл не найден: {file_path}")
        return False
    
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    pattern = r'(Stepik\s*=\s*)(\d+\.?\d*)'
    found = False
    for i, line in enumerate(lines):
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            lines[i] = f'{match.group(1)}{1}\n'
            found = True
            break
    
    if not found:
        if lines and not lines[-1].endswith('\n'):
            lines.append('\n')
        lines.append(f'Stepik = 1\n')
    
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"Stepik установлен в 1 в файле {file_path}")
        return True
    except Exception as e:
        print("Ошибка сохранения Stepik:", e)
        return False

# Основной цикл
def main_loop():
    scaler, cntr, n_clusters, cluster_names = load_fcm_model()
    while True:
        print("Проверка данных...")
        data = extract_data_from_file(RAW_DATA_PATH)
        
        if data["player_exited"] is True and data["player_data_json"] is not None:
            print("Игрок вышел. Обрабатываю данные.")
            result = process_player_data(data["player_data_json"], scaler, cntr, n_clusters, cluster_names)
            set_player_exited_game(RAW_DATA_PATH, False)
            if result:
                if data["coef"] >= 1 and data["step"] == 0:
                    save_identify_coef(RESULT_FILE_PATH, data["coef"])
                    set_stepik(RAW_DATA_PATH)
                    save_processed_result(result, RESULT_FILE_PATH)
                elif data["step"] == 2:
                    print("FFFFFEFEFEFEFEFEFEFFEF")
                    save_identify_coef(RESULT_FILE_PATH, data["coef"])
                    set_stepik(RAW_DATA_PATH)
                    save_processed_result(result, RESULT_FILE_PATH)
        elif data["player_exited"] is False:
            print("Игрок в игре. Ожидаю выхода...")
        else:
            print("Ошибка: данные неполные или playerExitedGame не найден.")
        
        time.sleep(1)  # Проверка каждую секунду

# Запуск скрипта
if __name__ == "__main__":
    print("Запуск обработки данных WoW SavedVariables...")
    main_loop()


 



