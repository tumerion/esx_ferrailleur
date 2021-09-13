ESX                = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


TriggerEvent('esx_phone:registerNumber', 'ferrailleur', _U('ferrailleur_customer'), true, true)
TriggerEvent('esx_society:registerSociety', 'ferrailleur', 'ferrailleur', 'society_ferrailleur', 'society_ferrailleur', 'society_ferrailleur', {type = 'private'})



RegisterServerEvent('esx_ferrailleur:onNPCJobMissionCompleted')
AddEventHandler('esx_ferrailleur:onNPCJobMissionCompleted', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local total   = math.random(Config.NPCJobEarnings.min, Config.NPCJobEarnings.max);

	if xPlayer.job.grade >= 3 then
		total = total * 2
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_ferrailleur', function(account)
		account.addMoney(total)
	end)

	TriggerClientEvent("esx:showNotification", _source, _U('your_comp_earned').. total)
end)

RegisterServerEvent('esx_ferrailleur:getStockItem')
AddEventHandler('esx_ferrailleur:getStockItem', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_ferrailleur', function(inventory)
		local item = inventory.getItem(itemName)
		local sourceItem = xPlayer.getInventoryItem(itemName)


		if count > 0 and item.count >= count then

			if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('player_cannot_hold'))
			else
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_withdrawn', count, item.label))
			end
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('invalid_quantity'))
		end
	end)
end)

ESX.RegisterServerCallback('esx_ferrailleur:getStockItems', function(source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_ferrailleur', function(inventory)
		cb(inventory.items)
	end)
end)

RegisterServerEvent('esx_ferrailleur:putStockItems')
AddEventHandler('esx_ferrailleur:putStockItems', function(itemName, count)

  local xPlayer = ESX.GetPlayerFromId(source)
  local sourceItem = xPlayer.getInventoryItem(itemName)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_ferrailleur', function(inventory)

    local inventoryItem = inventory.getItem(itemName)

    if sourceItem.count >= count and count > 0 then
      xPlayer.removeInventoryItem(itemName, count)
      inventory.addItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('added') .. count .. ' ' .. item.label)

  end)

end)

ESX.RegisterServerCallback('esx_ferrailleur:getPlayerInventory', function(source, cb)
	local xPlayer    = ESX.GetPlayerFromId(source)
	local items      = xPlayer.inventory

	cb({items = items})
end)

---------------------------------------------------------------------------------------------------------
--AJOUT DU DEMANTELEMENT--
---------------------------------------------------------------------------------------------------------

RegisterNetEvent('esx_ferrailleur:Payment')
AddEventHandler('esx_ferrailleur:Payment', function(vehicle)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    DamageDone = (1000 - vehicle) * Config.MoneyLostPerHitPoint
    AmountToPay = math.floor(Config.Payment - DamageDone)

    if xPlayer ~= nil then

        if Config.PaymentInBlackMoney == true then
            xPlayer.addAccountMoney('black_money', AmountToPay)
            if AmountToPay <= 0 then
                TriggerClientEvent('esx:showAdvancedNotification', src, 'Logan Paul', '', 'La caisse est éclatée ! ~r~casse ~w~toi !', 'CHAR_MULTIPLAYER', 9)
            else
                TriggerClientEvent('esx:showAdvancedNotification', src, 'Logan Paul', '', 'Tu as reçu ~r~$'..AmountToPay..'! ~w~Reviens plus tard.', 'CHAR_MULTIPLAYER', 9)
            end
        else
            xPlayer.addMoney(AmountToPay)
            if AmountToPay <= 0 then
                TriggerClientEvent('esx:showAdvancedNotification', src, 'Logan Paul', '', 'La caisse est éclatée ! ~r~casse ~w~toi !', 'CHAR_MULTIPLAYER', 9)
            else
               TriggerClientEvent('esx:showAdvancedNotification', src, 'Logan Paul', '', 'Tu as reçu ~r~$'..AmountToPay..'! ~w~Reviens plus tard.', 'CHAR_MULTIPLAYER', 9)
           end 
        end
    end

end)
