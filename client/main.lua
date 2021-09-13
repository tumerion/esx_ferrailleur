local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local PlayerData              = {}
local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local CurrentlyTowedVehicle   = nil
local Blips                   = {}
local NPCOnJob                = false
local NPCTargetTowable        = nil
local NPCTargetTowableZone    = nil
local NPCHasSpawnedTowable    = false
local NPCLastCancel           = GetGameTimer() - 5 * 60000
local NPCHasBeenNextToTowable = false
local NPCTargetDeleterZone    = false
local IsDead                  = false
local IsBusy                  = false
local PedIsCloseToPed = false
local HasVehicleObjective = false
local PedHasTalked = false
local PedHasTalkedToBoss = false
local PedHasDeleteVeh = false
local PedIsAtChopShop = false
local HasGarageObjective = false
local CoupeDoors = {0, 1, 4, 5}
-- ajout animation ped --
local ConsawClient 		= false
-- ajout animation ped --

ESX                           = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(5000)
	PlayerData = ESX.GetPlayerData()
end)

function SelectRandomTowable()
	local index = GetRandomIntInRange(1,  #Config.Towables)

	for k,v in pairs(Config.Zones) do
		if v.Pos.x == Config.Towables[index].x and v.Pos.y == Config.Towables[index].y and v.Pos.z == Config.Towables[index].z then
			return k
		end
	end
end

function StartNPCJob()
	NPCOnJob = true

	NPCTargetTowableZone = SelectRandomTowable()
	local zone       = Config.Zones[NPCTargetTowableZone]

	Blips['NPCTargetTowableZone'] = AddBlipForCoord(zone.Pos.x,  zone.Pos.y,  zone.Pos.z)
	SetBlipRoute(Blips['NPCTargetTowableZone'], true)

	--ESX.ShowNotification(_U('drive_to_indicated'))
	 ESX.ShowAdvancedNotification('Patron', '', "Vas à l'endroit indiqué sur ton GPS.", 'CHAR_MULTIPLAYER', 1)
end

function StopNPCJob(cancel)
	if Blips['NPCTargetTowableZone'] ~= nil then
		RemoveBlip(Blips['NPCTargetTowableZone'])
		Blips['NPCTargetTowableZone'] = nil
	end

	if Blips['NPCDelivery'] ~= nil then
		RemoveBlip(Blips['NPCDelivery'])
		Blips['NPCDelivery'] = nil
	end

	Config.Zones.VehicleDelivery.Type = -1

	NPCOnJob                = true
	NPCTargetTowable        = nil
	NPCTargetTowableZone    = nil
	NPCHasSpawnedTowable    = false
	NPCHasBeenNextToTowable = false

	if cancel then
		--ESX.ShowNotification(_U('mission_canceled'))
		 ESX.ShowAdvancedNotification('Patron', '', "Déjà terminé ?", 'CHAR_MULTIPLAYER', 1)
	else

	end
end

function OpenFerrailleurActionsMenu()

	local elements = {
		{label = _U('vehicle_list'),   value = 'vehicle_list'},
		{label = _U('deposit_stock'),  value = 'put_stock'},
		{label = _U('withdraw_stock'), value = 'get_stock'}
	}

	if Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ferrailleur_actions', {
		css		= 'Ferrailleur',
		title    = _U('ferrailleur'),
		align    = 'left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'vehicle_list' then

			



				local elements = {
					{label = _U('flat_bed'),  value = 'flatbed'},
					{label = _U('tow_truck'), value = 'towtruck'}
				}

				if Config.EnablePlayerManagement and PlayerData.job ~= nil and (PlayerData.job.grade_name == 'boss' or PlayerData.job.grade_name == 'chef' or PlayerData.job.grade_name == 'experimente') then
					table.insert(elements, {label = 'slamvan', value = 'slamvan'})
				end

				ESX.UI.Menu.CloseAll()

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_vehicle', {
					css		= 'Fourrière',
					title    = _U('service_vehicle'),
					align    = 'left',
					elements = elements
				}, function(data, menu)
					
						local vehicleProps = data.current.value
						ESX.Game.SpawnVehicle(data.current.value, Config.Zones.VehicleSpawnPoint.Pos, 260.0, function(vehicle)
							ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
							local playerPed = PlayerPedId()
							local plate = 'WORK' .. math.random(100, 900)
							TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate) -- vehicle lock
							SetVehicleNumberPlateText(vehicle, plate)
							TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
						end)
					

					menu.close()
				end, function(data, menu)
					menu.close()
					OpenFerrailleurActionsMenu()
				end)

			


		elseif data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		elseif data.current.value == 'boss_actions' then
			TriggerEvent('esx_society:openBossMenu', 'ferrailleur', function(data, menu)
				menu.close()
			end, {wash = false})
		end

	end, function(data, menu)
		menu.close()

		--CurrentAction     = 'ferrailleur_actions_menu'
		--CurrentActionMsg  = _U('open_actions')
		CurrentActionData = {}
		PedHasTalkedToBoss = false
		
	end)
end


function OpenMobileFerrailleurActionsMenu()

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_ferrailleur_actions', {
		css		= 'metier',
		title    = _U('ferrailleur'),
		align    = 'left',
		elements = {
			{label = _U('hijack'),        value = 'hijack_vehicle'},
			{label = "Plateau : Placer / Déposer",      value = 'dep_vehicle'},
			{label = "Mettre en fourrière",       value = 'del_vehicle'},		

		}
	}, function(data, menu)
		if IsBusy then return end

		if data.current.value == 'hijack_vehicle' then

		local playerPed = PlayerPedId()
		local vehicle   = ESX.Game.GetVehicleInDirection()
		local coords    = GetEntityCoords(playerPed)

		if IsPedSittingInAnyVehicle(playerPed) then
			--ESX.ShowNotification(_U('inside_vehicle'))
			 ESX.ShowAdvancedNotification('Patron', '', "Et maintenant ?", 'CHAR_MULTIPLAYER', 1)
			return
		end

		if DoesEntityExist(vehicle) then
			IsBusy = true
			TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
			Citizen.CreateThread(function()
				exports['progressBars']:startUI(10000, "Crochetage")
				Citizen.Wait(10000)

				SetVehicleDoorsLocked(vehicle, 1)
				SetVehicleDoorsLockedForAllPlayers(vehicle, false)
				ClearPedTasksImmediately(playerPed)

				--ESX.ShowNotification(_U('vehicle_unlocked'))
				 ESX.ShowAdvancedNotification('Patron', '', "J'espère que c'est pour le boulot !", 'CHAR_MULTIPLAYER', 1)
				IsBusy = false
			end)
		else
			--ESX.ShowNotification(_U('no_vehicle_nearby'))
			 ESX.ShowAdvancedNotification('Patron', '', "Je te vois tu sais... et tu es trop loin du véhicule pour ça !", 'CHAR_MULTIPLAYER', 1)
		end

		elseif data.current.value == 'del_vehicle' then
			local playerPed = PlayerPedId()

			if IsPedSittingInAnyVehicle(playerPed) then
				local vehicle = GetVehiclePedIsIn(playerPed, false)

				if GetPedInVehicleSeat(vehicle, -1) == playerPed then
					--ESX.ShowNotification(_U('vehicle_impounded'))
					 ESX.ShowAdvancedNotification('Patron', '', "Un tas de ferraille en moins sur la route !", 'CHAR_MULTIPLAYER', 1)
					ESX.Game.DeleteVehicle(vehicle)
				else
					--ESX.ShowNotification(_U('must_seat_driver'))
					 ESX.ShowAdvancedNotification('Patron', '', "Tu dois être à la place du conducteur...", 'CHAR_MULTIPLAYER', 1)
				end
			else
				local vehicle = ESX.Game.GetVehicleInDirection()

				if DoesEntityExist(vehicle) then
					--ESX.ShowNotification(_U('vehicle_impounded'))
					 ESX.ShowAdvancedNotification('Patron', '', "Un tas de ferraille en moins sur la route !", 'CHAR_MULTIPLAYER', 1)
					ESX.Game.DeleteVehicle(vehicle)
				else
					--ESX.ShowNotification(_U('must_near'))
					 ESX.ShowAdvancedNotification('Patron', '', "T'es couillon toi non ? T'es trop loin du véhicule !", 'CHAR_MULTIPLAYER', 1)
				end
			end
		elseif data.current.value == 'dep_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(playerPed, true)

		local towmodel = GetHashKey('flatbed')
		local isVehicleTow = IsVehicleModel(vehicle, towmodel)

		if isVehicleTow then
			local targetVehicle = ESX.Game.GetVehicleInDirection()

			if CurrentlyTowedVehicle == nil then
				if targetVehicle ~= 0 then
					if not IsPedInAnyVehicle(playerPed, true) then
						if vehicle ~= targetVehicle then
							AttachEntityToEntity(targetVehicle, vehicle, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
							CurrentlyTowedVehicle = targetVehicle
							--ESX.ShowNotification(_U('vehicle_success_attached'))
							 ESX.ShowAdvancedNotification('Patron', '', "C'est bien mon grand. Allez la suite !", 'CHAR_MULTIPLAYER', 1)

							if NPCOnJob then
								if NPCTargetTowable == targetVehicle then
									--ESX.ShowNotification(_U('please_drop_off'))
									 ESX.ShowAdvancedNotification('Patron', '', "Tu sais ce qu'il te reste à faire avec.", 'CHAR_MULTIPLAYER', 1)
									Config.Zones.VehicleDelivery.Type = 1

									if Blips['NPCTargetTowableZone'] ~= nil then
										RemoveBlip(Blips['NPCTargetTowableZone'])
										Blips['NPCTargetTowableZone'] = nil
									end

									Blips['NPCDelivery'] = AddBlipForCoord(Config.Zones.VehicleDelivery.Pos.x, Config.Zones.VehicleDelivery.Pos.y, Config.Zones.VehicleDelivery.Pos.z)
									SetBlipRoute(Blips['NPCDelivery'], true)
								end
							end
						else
							--ESX.ShowNotification(_U('cant_attach_own_tt'))
							 ESX.ShowAdvancedNotification('Patron', '', "Tu veux vraiment attacher ton propre véhicule là ?!", 'CHAR_MULTIPLAYER', 1)
						end
					end
				else
					--ESX.ShowNotification(_U('no_veh_att'))
					 ESX.ShowAdvancedNotification('Patron', '', "Y'a plus rien d'attaché là...", 'CHAR_MULTIPLAYER', 1)
				end
			else

				AttachEntityToEntity(CurrentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
				DetachEntity(CurrentlyTowedVehicle, true, true)

				if NPCOnJob then
					if NPCTargetDeleterZone then

						if CurrentlyTowedVehicle == NPCTargetTowable then
							ESX.Game.DeleteVehicle(NPCTargetTowable)
							TriggerServerEvent('esx_ferrailleur:onNPCJobMissionCompleted')
							StopNPCJob()
							NPCTargetDeleterZone = false
						else
							--ESX.ShowNotification(_U('not_right_veh'))
							 ESX.ShowAdvancedNotification('Patron', '', "Ce n'est pas le bon véhicule.", 'CHAR_MULTIPLAYER', 1)
						end

					else
						--ESX.ShowNotification(_U('not_right_place'))
						 ESX.ShowAdvancedNotification('Patron', '', "Ce n'est pas le bon endroit...", 'CHAR_MULTIPLAYER', 1)
					end
				end

				CurrentlyTowedVehicle = nil
				--ESX.ShowNotification(_U('veh_det_succ'))
				 ESX.ShowAdvancedNotification('Patron', '', "Bon boulot !", 'CHAR_MULTIPLAYER', 1)

			end
		else
			--ESX.ShowNotification(_U('imp_flatbed'))
			 ESX.ShowAdvancedNotification('Patron', '', "Allez ça dégage !", 'CHAR_MULTIPLAYER', 1)
		end


	end

	end, function(data, menu)
		menu.close()
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_ferrailleur:getStockItems', function(items)

		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu',
		{
			css		= 'Ferrailleur',
			title    = _U('ferrailleur_stock'),
			align    = 'left',
			elements = elements
		}, function(data, menu)

			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					--ESX.ShowNotification(_U('invalid_quantity'))
					 ESX.ShowAdvancedNotification('Patron', '', "Qu'est-ce que tu fais dans mon coffre là ?!", 'CHAR_MULTIPLAYER', 1)
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_ferrailleur:getStockItem', itemName, count)

					Citizen.Wait(1000)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)

		end, function(data, menu)
			menu.close()
		end)

	end)

end

function OpenPutStocksMenu()

	ESX.TriggerServerCallback('esx_ferrailleur:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type  = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			css		= 'Ferrailleur',
			title    = _U('inventory'),
			align    = 'left',
			elements = elements
		}, function(data, menu)

			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					--ESX.ShowNotification(_U('invalid_quantity'))
					 ESX.ShowAdvancedNotification('Patron', '', "Qu'est-ce que tu fais dans mon coffre là ?!", 'CHAR_MULTIPLAYER', 1)
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_ferrailleur:putStockItems', itemName, count)

					Citizen.Wait(1000)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)

	end)

end


RegisterNetEvent('esx_ferrailleur:onHijack')
AddEventHandler('esx_ferrailleur:onHijack', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle = nil

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		local chance = math.random(100)
		local alarm  = math.random(100)

		if DoesEntityExist(vehicle) then
			if alarm <= 33 then
				SetVehicleAlarm(vehicle, true)
				StartVehicleAlarm(vehicle)
			end

			TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)

			Citizen.CreateThread(function()
				exports['progressBars']:startUI(10000, "Crochetage")
				Citizen.Wait(10000)
				if chance <= 66 then
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ClearPedTasksImmediately(playerPed)
					--ESX.ShowNotification(_U('veh_unlocked'))
					 ESX.ShowAdvancedNotification('Patron', '', "C'est pour le boulot j'espère ?", 'CHAR_MULTIPLAYER', 1)
				else
					--ESX.ShowNotification(_U('hijack_failed'))
					 ESX.ShowAdvancedNotification('Patron', '', "Tu veux que j'appelle la police ou quoi ?", 'CHAR_MULTIPLAYER', 1)
					ClearPedTasksImmediately(playerPed)
				end
			end)

		end
	end
end)



RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

AddEventHandler('esx_ferrailleur:hasEnteredMarker', function(zone)
	if zone == NPCJobTargetTowable then

	elseif zone =='VehicleDelivery' then
		NPCTargetDeleterZone = true
	end
end)

AddEventHandler('esx_ferrailleur:hasExitedMarker', function(zone)
	if zone =='VehicleDelivery' then
		NPCTargetDeleterZone = false

	end

	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

AddEventHandler('esx_ferrailleur:hasEnteredEntityZone', function(entity)
	local playerPed = PlayerPedId()

	if hasJob and not IsPedInAnyVehicle(playerPed, false) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('press_remove_obj')
		CurrentActionData = {entity = entity}
	end
end)

AddEventHandler('esx_ferrailleur:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then
		CurrentAction = nil
	end
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = _U('ferrailleur'),
		number     = 'ferrailleur',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEwAACxMBAJqcGAAAA4BJREFUWIXtll9oU3cUx7/nJA02aSSlFouWMnXVB0ejU3wcRteHjv1puoc9rA978cUi2IqgRYWIZkMwrahUGfgkFMEZUdg6C+u21z1o3fbgqigVi7NzUtNcmsac40Npltz7S3rvUHzxQODec87vfD+/e0/O/QFv7Q0beV3QeXqmgV74/7H7fZJvuLwv8q/Xeux1gUrNBpN/nmtavdaqDqBK8VT2RDyV2VHmF1lvLERSBtCVynzYmcp+A9WqT9kcVKX4gHUehF0CEVY+1jYTTIwvt7YSIQnCTvsSUYz6gX5uDt7MP7KOKuQAgxmqQ+neUA+I1B1AiXi5X6ZAvKrabirmVYFwAMRT2RMg7F9SyKspvk73hfrtbkMPyIhA5FVqi0iBiEZMMQdAui/8E4GPv0oAJkpc6Q3+6goAAGpWBxNQmTLFmgL3jSJNgQdGv4pMts2EKm7ICJB/aG0xNdz74VEk13UYCx1/twPR8JjDT8wttyLZtkoAxSb8ZDCz0gdfKxWkFURf2v9qTYH7SK7rQIDn0P3nA0ehixvfwZwE0X9vBE/mW8piohhl1WH18UQBhYnre8N/L8b8xQvlx4ACbB4NnzaeRYDnKm0EALCMLXy84hwuTCXL/ExoB1E7qcK/8NCLIq5HcTT0i6u8TYbXUM1cAyyveVq8Xls7XhYrvY/4n3gC8C+dsmAzL1YUiyfWxvHzsy/w/dNd+KjhW2yvv/RfXr7x9QDcmo1he2RBiCCI1Q8jVj9szPNixVfgz+UiIGyDSrcoRu2J16d3I6e1VYvNSQjXpnucAcEPUOkGYZs/l4uUhowt/3kqu1UIv9n90fAY9jT3YBlbRvFTD4fw++wHjhiTRL/bG75t0jI2ITcHb5om4Xgmhv57xpGOg3d/NIqryOR7z+r+MC6qBJB/ZB2t9Om1D5lFm843G/3E3HI7Yh1xDRAfzLQr5EClBf/HBHK462TG2J0OABXeyWDPZ8VqxmBWYscpyghwtTd4EKpDTjCZdCNmzFM9k+4LHXIFACJN94Z6FiFEpKDQw9HndWsEuhnADVMhAUaYJBp9XrcGQKJ4qFE9k+6r2+MG3k5N8VQ22TVglbX2ZwOzX2VvNKr91zmY6S7N6zqZicVT2WNLyVSehESaBhxnOALfMeYX+K/S2yv7wmMAlvwyuR7FxQUyf0fgc/jztfkJr7XeGgC8BJJgWNV8ImT+AAAAAElFTkSuQmCC'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- Pop NPC mission vehicle when inside area
Citizen.CreateThread(function()
	while true do

		Citizen.Wait(200)

		if NPCTargetTowableZone ~= nil and not NPCHasSpawnedTowable then
			local coords = GetEntityCoords(PlayerPedId())
			local zone   = Config.Zones[NPCTargetTowableZone]

			if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < Config.NPCSpawnDistance then
				local model = Config.Vehicles[GetRandomIntInRange(1,  #Config.Vehicles)]

				ESX.Game.SpawnVehicle(model, zone.Pos, 0, function(vehicle)
					NPCTargetTowable = vehicle
				end)

				NPCHasSpawnedTowable = true
			end
		end

		if NPCTargetTowableZone ~= nil and NPCHasSpawnedTowable and not NPCHasBeenNextToTowable then
			local coords = GetEntityCoords(PlayerPedId())
			local zone   = Config.Zones[NPCTargetTowableZone]

			if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < Config.NPCNextToDistance then
				--ESX.ShowNotification(_U('please_tow'))
				 ESX.ShowAdvancedNotification('Patron', '', "Occupe toi de ça.", 'CHAR_MULTIPLAYER', 1)
				NPCHasBeenNextToTowable = true
			end
		end

	end
end)

-- Create Blips
Citizen.CreateThread(function()
	--local blip = AddBlipForCoord(Config.Zones.FerrailleurActions.Pos.x, Config.Zones.FerrailleurActions.Pos.y, Config.Zones.FerrailleurActions.Pos.z)
	local blip = AddBlipForCoord(Config.BlipLocation.Pos.x, Config.BlipLocation.Pos.y, Config.BlipLocation.Pos.z)

	SetBlipSprite (blip, 67)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipColour (blip, 3)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("~o~Les Ferrailleurs | Fourrière")
	EndTextCommandSetBlipName(blip)
end)

-- Display markers
Citizen.CreateThread(function()
	while true do
		local attente = 1000
		--if PlayerData.job ~= nil and PlayerData.job.name == 'ferrailleur' then
			local coords = GetEntityCoords(PlayerPedId())

			for k,v in pairs(Config.Zones) do
				if GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance then
					attente = 0
					DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
				end
			end
			--Citizen.Wait(attente)
		--end
		Citizen.Wait(attente)
	end
end)

-- check job
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2500)
        if ESX ~= nil then
            PlayerData = ESX.GetPlayerData()
            if PlayerData.job ~= nil and PlayerData.job.name == 'ferrailleur' then
                hasJob = true
                break
            else
                hasJob = false
            end
        end
    end
end)
-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do
		local attente = 1000

		if hasJob then

			local coords      = GetEntityCoords(PlayerPedId())
			local isInMarker  = false
			local currentZone = nil

			for k,v in pairs(Config.Zones) do
				if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
				isInMarker  = true
				currentZone = k
				attente = 1
				end
			end

			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker = true
				LastZone                = currentZone
				TriggerEvent('esx_ferrailleur:hasEnteredMarker', currentZone)
			end

			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_ferrailleur:hasExitedMarker', LastZone)
			end

		end
		Citizen.Wait(attente)
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local touchemenu = IsControlJustReleased(0, Keys['F7'])
		local touchemission = IsControlJustReleased(0, Keys['HOME'])
		--if IsControlJustReleased(0, Keys['F6']) and not IsDead and hasJob then
		if touchemenu and not IsDead and hasJob then
			OpenMobileFerrailleurActionsMenu()
		end

		if touchemission and not IsDead and hasJob then

			if NPCOnJob then

				if GetGameTimer() - NPCLastCancel > 5 * 60000 then
					StopNPCJob(true)
					NPCLastCancel = GetGameTimer()
				else
					--ESX.ShowNotification(_U('wait_five'))
					 ESX.ShowAdvancedNotification('Patron', '', "Tu crois que l'argent tombe du ciel ? Reviens plus tard !", 'CHAR_MULTIPLAYER', 1)
				end

			else

				local playerPed = PlayerPedId()

				if IsPedInAnyVehicle(playerPed, false) and IsVehicleModel(GetVehiclePedIsIn(playerPed, false), GetHashKey("flatbed")) then
					StartNPCJob()
				else
					--ESX.ShowNotification(_U('must_in_flatbed'))
					 ESX.ShowAdvancedNotification('Patron', '', "Tu dois être dans un flatbed couillon !", 'CHAR_MULTIPLAYER', 1)
				end

			end

		end

	end
end)

AddEventHandler('esx:onPlayerDeath', function()
	IsDead = true
end)

AddEventHandler('playerSpawned', function(spawn)
	IsDead = false
end)

---------------------------------------------------------------------------------------------------------
--NB : gestion des menu
---------------------------------------------------------------------------------------------------------

RegisterNetEvent('NB:openMenuFerrailleur')
AddEventHandler('NB:openMenuFerrailleur', function()
	OpenMobileFerrailleurActionsMenu()
end)

---------------------------------------------------------------------------------------------------------
--AJOUT DU DEMANTELEMENT--
---------------------------------------------------------------------------------------------------------
--Creating the NPC
Citizen.CreateThread(function()
  local NPCModel = Config.NPCModel
  RequestModel(NPCModel)

  while not HasModelLoaded(NPCModel) do
      Citizen.Wait(1000)
  end

  --local NPC = CreatePed(4, Config.NPCModel, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z, Config.NPCLocation.h, false, true)
  local NPC = CreatePed(4, Config.NPCModel, 2344.03, 3051.88, 47.15, 266.39, false, true)
  SetPedFleeAttributes(NPC, 2)
  SetBlockingOfNonTemporaryEvents(NPC, true)
  SetPedCanRagdollFromPlayerImpact(NPC, false)
  SetPedDiesWhenInjured(NPC, false)
  FreezeEntityPosition(NPC, true)
  SetEntityInvincible(NPC, true)
  SetPedCanPlayAmbientAnims(NPC, true)
  TaskStartScenarioInPlace(NPC, "WORLD_HUMAN_DRUG_DEALER", 0, false)  
  
  local BossModel = Config.BossModel
  RequestModel(BossModel)

  while not HasModelLoaded(BossModel) do
      Citizen.Wait(1000)
  end


  local BOSS = CreatePed(4, Config.BossModel, 2340.61, 3126.16, 47.20, 348.20, false, true)
  SetPedFleeAttributes(BOSS, 2)
  SetBlockingOfNonTemporaryEvents(BOSS, true)
  SetPedCanRagdollFromPlayerImpact(BOSS, false)
  SetPedDiesWhenInjured(BOSS, false)
  FreezeEntityPosition(BOSS, true)
  SetEntityInvincible(BOSS, true)
  SetPedCanPlayAmbientAnims(BOSS, true)
  TaskStartScenarioInPlace(BOSS, "WORLD_HUMAN_DRUG_DEALER", 0, false)  
  
  
  local DeleteModel = Config.DeleteModel
  RequestModel(DeleteModel)

  while not HasModelLoaded(DeleteModel) do
      Citizen.Wait(1000)
  end


  local DELETEVEH = CreatePed(4, Config.DeleteModel, 2349.90, 3105.33, 47.26, 180.51, false, true)
  SetPedFleeAttributes(DELETEVEH, 2)
  SetBlockingOfNonTemporaryEvents(DELETEVEH, true)
  SetPedCanRagdollFromPlayerImpact(DELETEVEH, false)
  SetPedDiesWhenInjured(DELETEVEH, false)
  FreezeEntityPosition(DELETEVEH, true)
  SetEntityInvincible(DELETEVEH, true)
  SetPedCanPlayAmbientAnims(DELETEVEH, true)
  TaskStartScenarioInPlace(DELETEVEH, "WORLD_HUMAN_DRUG_DEALER", 0, false)
end)

--Checking the distance
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1000)
    PlayerCoords = GetEntityCoords(PlayerPedId())

    if Get3DDistance(PlayerCoords, Config.NPCLocation) < 3 and PedHasTalked == false then
      PedIsCloseToPed = true
    else
      PedIsCloseToPed = false
    end
	
    if Get3DDistance(PlayerCoords, Config.BossLocation) < 3 and PedHasTalkedToBoss == false then
      PedIsCloseToBoss = true
    else
      PedIsCloseToBoss = false
    end	
	
    if Get3DDistance(PlayerCoords, Config.DelVehLocation) < 3 and PedHasDeleteVeh == false then
      PedIsCloseToDelete = true
    else
      PedIsCloseToDelete = false
    end
	
	
  end
end)

function MarkerPNJ()
	if PedIsCloseToPed == true then
		MarkerPNJZone = Config.NPCLocation
	Draw3DText(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z+1.25, "Appuie sur ~r~[E] ~w~pour ~r~parler ~w~avec Logan Paul", 0.4)
	end
	
	if PedIsCloseToBoss == true then
		MarkerPNJZone = Config.BossLocation
	Draw3DText(Config.BossLocation.x, Config.BossLocation.y, Config.BossLocation.z+1.25, "Appuie sur ~r~[E] ~w~pour ~r~parler ~w~avec le Boss", 0.4)
	end
	
	if PedIsCloseToDelete == true then
		MarkerPNJZone = Config.DelVehLocation
	Draw3DText(Config.DelVehLocation.x, Config.DelVehLocation.y, Config.DelVehLocation.z+1.25, "Appuie sur ~r~[E] ~w~pour ~r~parler ~w~ranger le véhicule.", 0.4)
	end
	
	if PedIsAtChopShop == true then
	Draw3DText(randomGarage.x, randomGarage.y, randomGarage.z, "Appuie sur ~r~[E] ~w~pour ~r~démanteler ~w~le véhicule", 0.4)
	end
	
end


-- Local pour animation ped --
local attachedConsaw
local consawSound
-- Local pour animation ped --

local MarkerPNJZone
--Drawing the marker if the player is close
Citizen.CreateThread(function()
  while true do
    local attente = 1000
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	local latouche = IsControlJustReleased(0, 51)
    
	if PedIsCloseToPed == true and PedHasTalked == false 
	or PedIsCloseToBoss == true and PedHasTalkedToBoss == false
	or PedIsCloseToDelete == true and PedHasDeleteVeh == false
	then
	attente = 0
	MarkerPNJ()
    end

    --Talk to the ped
    if hasJob and latouche and PedIsCloseToPed == true then
		GoCheck()
	  else
	  if latouche and PedIsCloseToPed == true then
	  ESX.ShowAdvancedNotification('Logan Paul', '', "Casse toi de là tu bosses pas ici !", 'CHAR_MULTIPLAYER', 1)
	  end
    end

    --Talk to the Boss
    if hasJob and latouche and PedIsCloseToBoss == true then
		Yakoi()
	  else
	  if latouche and PedIsCloseToBoss == true then
	  ESX.ShowAdvancedNotification('Boss', '', "Casse toi de là tu bosses pas ici !", 'CHAR_MULTIPLAYER', 1)
	  end
    end

    --Talk to delete vehicle
     if latouche and PedIsCloseToDelete == true then
		Parking()
	  else
	  if latouche and PedIsCloseToDelete == true then
	  ESX.ShowAdvancedNotification('Manu', '', "Casse toi de là tu bosses pas ici !", 'CHAR_MULTIPLAYER', 1)
	  end
    end

    --Chop the vehicle
    if latouche and PedIsAtChopShop then
		Tchao()      
    end
	Citizen.Wait(attente)
  end
end)

--Getting a random vehicle
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1000)
    if PedHasTalked == true and HasVehicleObjective == false then
      GetRandomVehicle()
    end

    if GetVehiclePedIsIn((GetPlayerPed(-1)), false) == vehicleToFind and HasGarageObjective == false then
      RemoveBlip(VehicleBlip)
      GetRandomGarage()
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    --Citizen.Wait(1000)
	local attente = 1000
    if HasGarageObjective == true then
      if Get3DDistance(PlayerCoords, randomGarage) < 5 then
        PedIsAtChopShop = true
      else
        PedIsAtChopShop = false
      end
    end
	Citizen.Wait(attente)
  end
end)
--opti touches--
function GoCheck()
      exports['progressBars']:startUI(10000, "Discussion")
      TaskStartScenarioInPlace(GetPlayerPed(-1), "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
      Citizen.Wait(10000)
      ESX.ShowAdvancedNotification('Logan Paul', '', "Vas me chercher cette bagnole et ramène là à la casse pour être payé.", 'CHAR_MULTIPLAYER', 1)
	  Citizen.Wait(3000)
      PedHasTalked = true
      ClearPedTasksImmediately(GetPlayerPed(-1))
end
function Yakoi()
      exports['progressBars']:startUI(1000, "Discussion")
      TaskStartScenarioInPlace(GetPlayerPed(-1), "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
      Citizen.Wait(1000)
      ESX.ShowAdvancedNotification('Boss', '', "Dis moi ce que tu veux faire ?", 'CHAR_MULTIPLAYER', 1)
	  Citizen.Wait(1000)
      PedHasTalkedToBoss = true
      ClearPedTasksImmediately(GetPlayerPed(-1))
	  OpenFerrailleurActionsMenu()
	  PedHasTalkedToBoss = false
end
function Parking()
	local playerPed = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	if hasJob and IsPedSittingInAnyVehicle(playerPed) then
	
      exports['progressBars']:startUI(1000, "Discussion")
	  ESX.ShowAdvancedNotification('Manu', '', "J'espère qu'il est en bon état !", 'CHAR_MULTIPLAYER', 1)
	  Citizen.Wait(1000)
      PedHasDeleteVeh = true
	  Citizen.Wait(1000)
	  ESX.Game.DeleteVehicle(vehicle)
	  PedHasDeleteVeh = false
	end
end
function Desossage()
            SetVehicleDoorOpen(vehicleToFind, v, false, false)
            exports['progressBars']:startUI(Config.ChoppingTime, 'Démantèlement en cours')

		--animation ped--
			local ped = GetPlayerPed(-1)
			local boneIndex = GetPedBoneIndex(ped, 28422)
			local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
			local animDict = "anim@heists@fleeca_bank@drilling"
			local animLib = "drill_straight_idle"
					
			TaskLeaveVehicle(ped, vehicle, 16)
			Citizen.Wait(1000)
			RequestAnimDict(animDict)
			while not HasAnimDictLoaded(animDict) do
				Citizen.Wait(50)
			end
			
			local consawProp = GetHashKey('prop_tool_consaw')
			local boneIndex = GetPedBoneIndex(ped, 28422)
			
			RequestModel(consawProp)
			while not HasModelLoaded(consawProp) do
				Citizen.Wait(100)
			end
			TaskPlayAnim(ped,'anim@heists@fleeca_bank@drilling','drill_straight_idle',1.0, -1.0, -1, 2, 0, 0, 0, 0)
			attachedConsaw = CreateObject(consawProp, 1.0, 1.0, 1.0, 1, 1, 0)
			AttachEntityToEntity(attachedConsaw, ped, boneIndex, 0.0, 0, 0.0, 10.0, 10.0, 90.0, 1, 1, 0, 0, 2, 1)
			RequestAmbientAudioBank("DLC_HEIST_FLEECA_SOUNDSET", 0)
			RequestAmbientAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL", 0)
			RequestAmbientAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL_2", 0)
			consawSound = GetSoundId()
			PlaySoundFromEntity(consawSound, "Drill", attachedConsaw, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)

			--animation ped fin--
			
            Citizen.Wait(Config.ChoppingTime)
            SetVehicleDoorBroken(vehicleToFind, v, false)
			
			--clear animation ped--
			ClearPedTasksImmediately(ped)
			StopSound(consawSound)
			ReleaseSoundId(consawSound)
			DeleteEntity(attachedConsaw)
end
function Desossage2()
            SetVehicleDoorOpen(vehicleToFind, v, false, false)
            exports['progressBars']:startUI(Config.ChoppingTime, 'Démantèlement en cours')

		--animation ped--
			local ped = GetPlayerPed(-1)
			local boneIndex = GetPedBoneIndex(ped, 28422)
			local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
			local animDict = "anim@heists@fleeca_bank@drilling"
			local animLib = "drill_straight_idle"
			
			TaskLeaveVehicle(ped, vehicle, 16)
			Citizen.Wait(1000)
			RequestAnimDict(animDict)
			while not HasAnimDictLoaded(animDict) do
				Citizen.Wait(50)
			end
			
			local consawProp = GetHashKey('prop_tool_consaw')
			local boneIndex = GetPedBoneIndex(ped, 28422)
			
			RequestModel(consawProp)
			while not HasModelLoaded(consawProp) do
				Citizen.Wait(100)
			end
			TaskPlayAnim(ped,'anim@heists@fleeca_bank@drilling','drill_straight_idle',1.0, -1.0, -1, 2, 0, 0, 0, 0)
			attachedConsaw = CreateObject(consawProp, 1.0, 1.0, 1.0, 1, 1, 0)
			AttachEntityToEntity(attachedConsaw, ped, boneIndex, 0.0, 0, 0.0, 10.0, 10.0, 90.0, 1, 1, 0, 0, 2, 1)
			RequestAmbientAudioBank("DLC_HEIST_FLEECA_SOUNDSET", 0)
			RequestAmbientAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL", 0)
			RequestAmbientAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL_2", 0)
			consawSound = GetSoundId()
			PlaySoundFromEntity(consawSound, "Drill", attachedConsaw, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
			--animation ped fin--
			
            Citizen.Wait(Config.ChoppingTime)
            SetVehicleDoorBroken(vehicleToFind, v, false, false)
			-- clear animation ped--
			ClearPedTasksImmediately(ped)
			StopSound(consawSound)
			ReleaseSoundId(consawSound)
			DeleteEntity(attachedConsaw)
			-- clear animation ped--
end

function Tchao()
      if GetVehiclePedIsIn(GetPlayerPed(-1), false) ~= vehicleToFind then
        --ESX.ShowNotification("Ce n'est pas le bon véhicule")
		 ESX.ShowAdvancedNotification('Patron', '', "Ce n'est pas le bon véhicule.", 'CHAR_MULTIPLAYER', 1)
      else
        local NumberOfDoors = GetNumberOfVehicleDoors(vehicleToFind)

        FreezeEntityPosition(vehicleToFind, true)
        if NumberOfDoors > 4 then
          for v = 0, NumberOfDoors-1 do
			Desossage()
          end
        else
          for k, v in pairs(CoupeDoors) do
			Desossage2()
          end
        end

        exports['progressBars']:startUI(Config.FinishingUpTime, 'C\'est bientôt terminé...')
        Citizen.Wait(Config.FinishingUpTime)

        Health = GetVehicleBodyHealth(vehicleToFind)
        TriggerServerEvent('esx_ferrailleur:Payment', Health)

        RemoveBlip(GarageBlip)
        FreezeEntityPosition(vehicleToFind, false)
        DeleteEntity(vehicleToFind)
        vehiclePlate = ''
        PedIsAtChopShop = false
        HasVehicleObjective = false
        HasGarageObjective = false
        PedHasTalked = false

        if Config.EnableCooldown == true then
          Citizen.Wait(Config.Cooldown)
        end
	end
end
--opti touches--

function GetRandomGarage()
  HasGarageObjective = true
  math.randomseed(GetGameTimer())
  randomGarage = Config.DeliveryGarages[math.random(#Config.DeliveryGarages)]

  GarageBlip = AddBlipForCoord(randomGarage.x, randomGarage.y, randomGarage.z)
  SetBlipSprite(GarageBlip, 1) -- Blip icon
  SetBlipScale(GarageBlip, 0.9) -- Blip size (Value of 1 breaks it for some reason)
  SetBlipColour(GarageBlip, 1) -- Taxi Yellow color (5)
  SetBlipDisplay(GarageBlip, 2) -- Show both on map and minimap (2)
  SetBlipAsShortRange(GarageBlip, false) -- BLip only appears when it's in range
  SetBlipRoute(GarageBlip, true)

  BeginTextCommandSetBlipName("STRING") -- Text type String
  AddTextComponentString('Casse') -- String name
  EndTextCommandSetBlipName(GarageBlip)

  return randomGarage
end

function GetRandomVehicle()
  HasVehicleObjective = true
  math.randomseed(GetGameTimer())
  local randomVehicle = Config.Vehicles[math.random(#Config.Vehicles)]
  local randomCoords = Config.VehicleLocations[math.random(#Config.VehicleLocations)]


  ESX.Game.SpawnVehicle(randomVehicle, vector3(randomCoords.x, randomCoords.y, randomCoords.z), randomCoords.h, function(vehicle)
    vehicleToFind = vehicle
    vehiclePlate = GetVehicleNumberPlateText(vehicle)
	SetVehicleNumberPlateText(vehicle, "mission")
  end)

  VehicleBlip = AddBlipForCoord(randomCoords.x, randomCoords.y, randomCoords.z)
  SetBlipSprite(VehicleBlip, 1) -- Blip icon
  SetBlipScale(VehicleBlip, 0.9) -- Blip size (Value of 1 breaks it for some reason)
  SetBlipColour(VehicleBlip, 1) -- Taxi Yellow color (5)
  SetBlipDisplay(VehicleBlip, 2) -- Show both on map and minimap (2)
  SetBlipAsShortRange(VehicleBlip, false) -- BLip only appears when it's in range
  SetBlipRoute(VehicleBlip, true)

  BeginTextCommandSetBlipName("STRING") -- Text type String
  AddTextComponentString('Véhicule') -- String name
  EndTextCommandSetBlipName(VehicleBlip)
  return vehicleToFind
end

function Get3DDistance(originCoords, objectCoords)
  return math.sqrt((objectCoords.x - originCoords.x) ^ 2 + (objectCoords.y - originCoords.y) ^ 2 + (objectCoords.z - originCoords.z) ^ 2)
end

function Draw3DText(x, y, z, text)
  local onScreen, _x, _y = World3dToScreen2d(x, y, z)
  local pX, pY, pZ = table.unpack(GetGameplayCamCoords())

  SetTextScale(0.35, 0.35)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextEntry("STRING")
  SetTextCentre(true)
  SetTextColour(255, 255, 255, 215)
  AddTextComponentString(text)
  DrawText(_x, _y)
  
  local factor = (string.len(text)) / 700
  DrawRect(_x, _y + 0.0150, 0.06 + factor, 0.03, 41, 11, 41, 100)
end
